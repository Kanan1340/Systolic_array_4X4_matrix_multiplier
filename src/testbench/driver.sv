class sys_driver extends uvm_driver #(sys_seq_item);

  `uvm_component_utils(sys_driver)

  virtual sys_inf.drv vif;

  function new(string name = "sys_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(virtual sys_inf.drv)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", {"Driver did not get vif for ", get_full_name()})
  endfunction

  task run_phase(uvm_phase phase);
    reset_dut();
    forever begin
      seq_item_port.get_next_item(req);
      drive(req);
      seq_item_port.item_done();
    end
  endtask

  // Initial reset: hold ~3 clocks, release on a falling edge (away from posedge)
  task reset_dut();
    vif.rst_n = 1'b0;
    vif.drv_cb.ena    <= 1'b1;
    vif.drv_cb.ui_in  <= 8'h00;
    vif.drv_cb.uio_in <= 8'h00;
    `uvm_info("DRV", $sformatf("RESET asserted: rst_n=%0b", vif.rst_n), UVM_HIGH)
    repeat (3) @(negedge vif.clk);
    vif.rst_n = 1'b1;
    `uvm_info("DRV", $sformatf("RESET released: rst_n=%0b", vif.rst_n), UVM_HIGH)
    @(vif.drv_cb);                              // re-align to a rising edge
  endtask

  // Reset in the middle of an item (asynchronous assertion)
  task mid_reset();
    @(negedge vif.clk);
    vif.rst_n = 1'b0;
    vif.drv_cb.uio_in <= 8'h00;
    vif.drv_cb.ui_in  <= 8'h00;
    `uvm_info("DRV", $sformatf("MID-ITEM RESET asserted: rst_n=%0b", vif.rst_n), UVM_HIGH)
    repeat (3) @(negedge vif.clk);
    vif.rst_n = 1'b1;
    `uvm_info("DRV", $sformatf("MID-ITEM RESET released: rst_n=%0b", vif.rst_n), UVM_HIGH)
    @(vif.drv_cb);
  endtask

  task drive(sys_seq_item tx);
    int rst_at = tx.reset ? (tx.num_cycles / 2) : -1;

    `uvm_info("DRV",
      $sformatf("ITEM load_a=%0b load_b=%0b start=%0b read=%0b reset=%0b cycles=%0d",
                tx.load_a, tx.load_b, tx.start, tx.read, tx.reset, tx.num_cycles),
      UVM_HIGH)

    for (int i = 0; i < tx.num_cycles; i++) begin
      bit [7:0] uio_val, ui_val;
      uio_val = {4'b0000, tx.read, (i == 0) & tx.start, tx.load_b, tx.load_a};
      ui_val  = {tx.upper_nib, tx.in_arr[i % 16]};

      vif.drv_cb.uio_in <= uio_val;
      vif.drv_cb.ui_in  <= ui_val;
      `uvm_info("DRV", $sformatf("  cyc %0d: uio_in=%08b ui_in=0x%02h", i, uio_val, ui_val), UVM_HIGH)
      @(vif.drv_cb);

      if (i == rst_at) begin
        mid_reset();
        return;
      end
    end
     
    vif.drv_cb.uio_in <= 8'h00;
    `uvm_info("DRV", "  release cycle: uio_in=00000000", UVM_HIGH)
    @(vif.drv_cb);
  endtask

endclass


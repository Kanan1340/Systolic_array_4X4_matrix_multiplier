class sys_environment extends uvm_env;
        `uvm_component_utils(sys_environment)
        sys_agent active_agent,passive_agent;
        scoreboard scb;
        sys_subscriber sb;

        function new(string name="sys_environment", uvm_component parent);
                super.new(name,parent);
        endfunction
        function void build_phase(uvm_phase phase);

                super.build_phase(phase);
        uvm_config_db #(uvm_active_passive_enum):: set(this,"active_agent","is_active",UVM_ACTIVE);
        uvm_config_db #(uvm_active_passive_enum):: set(this,"passive_agent","is_active",UVM_PASSIVE);

                active_agent = sys_agent::type_id::create("active_agent",this);
        passive_agent = sys_agent::type_id::create("passive_agent",this);
                scb = scoreboard::type_id::create("scb",this);
                sb  = sys_subscriber::type_id::create("sb",this);

        endfunction

        function void connect_phase(uvm_phase phase);
                super.connect_phase(phase);

                active_agent.i_mon.in_ap.connect(scb.in_mon_imp);
                active_agent.i_mon.in_ap.connect(sb.analysis_export);
                passive_agent.o_mon.out_ap.connect(scb.out_mon_imp);

        endfunction

endclass



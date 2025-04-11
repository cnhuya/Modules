module deployer::simple{
  
    use std::signer;
    use std::vector;
    use std::account;
    use std::string;
    use std::timestamp;
    use std::table;
    use std::debug::print;
    

    const OWNER: address = @deployer;
    
    // ERROR CODES
    const ERROR_NOT_OWNER: u64 = 1;

    struct DATA has key, store, drop {number: u128, number2: u256, }

    entry fun innit(address: &signer){

        let addr = signer::address_of(address);

        if (!exists<DATA>(OWNER)) {
            move_to(address, DATA {number: 0, number2: 0, });
        };
    }

    public entry fun storeDATA(address: &signer, _number: u128, _number2: u256,) acquires DATA
    {
        let addr = signer::address_of(address);
        //odesilatel musi byt owner
        assert!(addr == OWNER, ERROR_NOT_OWNER);
        innit(address);

        let data = borrow_global_mut<DATA>(OWNER);

        //prepsani starych hodnot/dat na nove
        data.number = _number;
        data.number2 = _number2;
    }
 
    #[view]
    public fun viewDATA(): DATA acquires DATA
    {
        //"pujceni" ulozenych dat na adresse <OWNER>
        let _data = borrow_global_mut<DATA>(OWNER);

        //nacteni ulozenych dat do datoveho structu, ke kteremu patri
        let data = DATA{
            number: _data.number,
            number2: _data.number2,
            
        };
        //debug
        print(&data);
        //return
        move data
    }
 
    #[test(account = @0x1, owner = @0xc698c251041b826f1d3d4ea664a70674758e78918938d1b3b237418ff17b4020)]
    public entry fun test(account: signer, owner: signer) acquires DATA {
        storeDATA(&owner, 5,2);
        viewDATA();
    }
}

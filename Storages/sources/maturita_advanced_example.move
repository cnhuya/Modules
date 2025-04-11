module deployer::advanced{
  
    use std::signer;
    use std::vector;
    use std::account;
    use std::string;
    use std::timestamp;
    use std::table;
    use std::debug::print;

    const OWNER: address = @0xc698c251041b826f1d3d4ea664a70674758e78918938d1b3b237418ff17b4020;
    
    // ERROR CODES
    const ERROR_NOT_OWNER: u64 = 1;

    struct DATA has copy, key, store, drop {id: u64, number: u128, number2: u256, }

    struct HISTORICAL_DATA has key, store, drop, copy {database: vector<DATA>}

    struct COUNTER has copy, key, store, drop {count: u64}


    public entry fun storeDATA(address: &signer, _number: u128, _number2: u256,) acquires DATA, HISTORICAL_DATA, COUNTER
    {

        let addr = signer::address_of(address);

        if (!exists<DATA>(OWNER)) {
            move_to(address, DATA {id: 0, number: 0, number2: 0, });
        };

        if (!exists<HISTORICAL_DATA>(OWNER)) {
            move_to(address, HISTORICAL_DATA { database: vector::empty() });
        };

        if (!exists<COUNTER>(OWNER)) {
            move_to(address, COUNTER { count: 0 });
        };

        //odesilatel musi byt owner
        assert!(addr == OWNER, ERROR_NOT_OWNER);
        let data = borrow_global_mut<DATA>(OWNER);
        let counter = borrow_global_mut<COUNTER>(OWNER);
        //prepsani starych hodnot/dat na nove
        let id_count = counter.count + 1;

        let _data = DATA{
            id: id_count,
            number: _number,
            number2: _number2,
        };
        print(&_data);
        let database = borrow_global_mut<HISTORICAL_DATA>(OWNER);
        vector::push_back(&mut database.database, _data);
        counter.count = counter.count + 1;
    }
 
    #[view]
    public fun viewDATA(count: u64): DATA acquires HISTORICAL_DATA
    {
        //"pujceni" ulozenych dat na adresse <OWNER>
        assert!(exists<HISTORICAL_DATA>(OWNER), count);
        let database = borrow_global<HISTORICAL_DATA>(OWNER);    
        let data = vector::borrow(&database.database, count);

        //nacteni ulozenych dat do datoveho structu, ke kteremu patri
        let data = DATA{
            id: database.id,
            number: database.number,
            number2: database.number2,
        
        };

        //debug
        print(&data);
        //return
        move data
    }
 


     #[view]
    public fun viewALLDATA(): HISTORICAL_DATA acquires HISTORICAL_DATA
    {
        //"pujceni" ulozenych dat na adresse <OWNER>
        let historical_data = *borrow_global<HISTORICAL_DATA>(OWNER);    
        //let open_view = vector::borrow(&ohcl_Database.database, count);
        //nacteni ulozenych dat do datoveho structu, ke kteremu patri
        let _historical_data = HISTORICAL_DATA{
            database: historical_data.database,
        };

        //debug
        print(&_historical_data);
        //return
        move _historical_data
    }

 
    // Test function
    #[test(account = @0x1, owner = @0xc698c251041b826f1d3d4ea664a7067475 8e78918938d1b3b237418ff17b4020)]
    public entry fun test(account: signer, owner: signer) acquires DATA, HISTORICAL_DATA, COUNTER{
        storeDATA(&owner, 5,2);
        viewDATA(0);
        storeDATA(&owner, 50,20);
        viewALLDATA();
    }
}

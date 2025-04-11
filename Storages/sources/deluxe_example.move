module deployer::deluxe{
  
    use std::signer;
    use std::vector;
    use std::account;
    use std::timestamp;
    use std::table;
    use std::debug::print;
    use std::string::utf8;
    use std::string;

    // TODO
    // Pridat dalsi struct, ktery by ukladal stejne data jako DATA struct, akorat bez userID pro jednotlive uzivatele? Mozna by to davalo vetsi smysl pote pri vypisovani transakci uzivatele?
    // Optimalizace + kontrola zabezpeceni

    const OWNER: address = @deployer;
    
    // ERROR CODES
    const ERROR_NOT_OWNER: u64 = 1;
    const ERROR_VAR_NOT_INITIALIZED: u64 = 2;
    const ERROR_TX_DOESNT_EXISTS: u64 = 3;
    const ERROR_USER_DOESNT_EXISTS: u64 = 4;

    struct DATA has copy, key, store, drop {userID: u64, txID: u128, timestamp: u64, number: u128, number2: u256, }

    struct USER_DATA has copy,key,store,drop {id: u64, creation: u64, totalTX: u64 }

    struct HISTORICAL_DATA has key, store, drop, copy {database: vector<DATA>}

    struct TOTAL has key, store, drop, copy {totalUsers: u64, totalTX: u128}

    struct USER_TRANSACTIONS_DATABASE has key { transactions: table::Table<u64, vector<DATA>> }

    struct USER_DATABASE has key { users: table::Table<u64, USER_DATA> }
    
    struct DATABASE has copy, key, drop { database: vector<DATA> }


    entry fun innit(address: &signer) {
        //The transaction sender needs to be OWNER, otherwise returns error with a predefined code 1.
        let addr = signer::address_of(address);
        assert!(addr == OWNER, ERROR_NOT_OWNER);

        let user_data = USER_DATA{
            id: 0,
            creation: 0,
            totalTX: 0,
        };

        if (!exists<DATA>(OWNER)) {
            move_to(address, DATA {userID: 0, txID: 0,timestamp: 0, number: 0, number2: 0, });
        };

        if (!exists<HISTORICAL_DATA>(OWNER)) {
            move_to(address, HISTORICAL_DATA { database: vector::empty() });
        };

        if (!exists<TOTAL>(OWNER)) {
            move_to(address, TOTAL { totalUsers: 0, totalTX: 0 });
        };


        if (!exists<USER_TRANSACTIONS_DATABASE>(OWNER)) {
            move_to(address, USER_TRANSACTIONS_DATABASE { transactions: table::new<u64, vector<DATA>>() });
        };

        if (!exists<USER_DATABASE>(OWNER)) {
            let users_table = table::new<u64, USER_DATA>();
            move_to(address, USER_DATABASE { users: users_table });
        };
    }

    public entry fun storeDATA(address: &signer, _userID: u64, _number: u128, _number2: u256,) acquires DATA, HISTORICAL_DATA, USER_DATABASE, USER_TRANSACTIONS_DATABASE, TOTAL
    {

        let addr = signer::address_of(address);
        //The transaction sender needs to be OWNER, otherwise returns error with a predefined code 1.
        assert!(addr == OWNER, ERROR_NOT_OWNER);

        innit(address);

        let data = borrow_global_mut<DATA>(OWNER);
        let database_table = borrow_global_mut<USER_TRANSACTIONS_DATABASE>(OWNER);
        let users_table = borrow_global_mut<USER_DATABASE>(OWNER);
        let total_stats = borrow_global_mut<TOTAL>(OWNER);

        //Getting current unix time epoch from blockchain. (calling the now_seconds functions which returns unix epoch in seconds, replacable with now_microseconds()).
        let time = timestamp::now_seconds();

        if (table::contains(&users_table.users, _userID)) {
            let user = table::borrow_mut(&mut users_table.users, _userID);
            user.totalTX = user.totalTX + 1;
        } else {
            let user_data = USER_DATA{
                id: _userID,
                creation: time,
                totalTX: 1,
            };
            table::add(&mut users_table.users, _userID, user_data);
            total_stats.totalUsers = total_stats.totalUsers + 1;
        };

        let userCount = total_stats.totalUsers;
        assert!(_userID <= userCount, ERROR_USER_DOESNT_EXISTS);

        let tx_id = total_stats.totalTX;
        let _data = DATA{
            userID: _userID,
            txID: tx_id,
            timestamp: time,
            number: _number,
            number2: _number2,
        };

        // Add the transaction to the user's transaction list
        if (table::contains(&database_table.transactions, _userID)) {
            let transactions = table::borrow_mut(&mut database_table.transactions, _userID);
            vector::push_back(transactions, _data);
        } else {
            let transactions = vector::empty<DATA>();
            vector::push_back(&mut transactions, _data);
            table::add(&mut database_table.transactions, _userID, transactions);
        };

        print(&_data);
        let database = borrow_global_mut<HISTORICAL_DATA>(OWNER);
        vector::push_back(&mut database.database, _data);

        total_stats.totalTX = total_stats.totalTX + 1;

    }
 
    #[view]
    public fun viewDATA(count: u64): DATA acquires HISTORICAL_DATA
    {
        //"pujceni" ulozenych dat na adresse <OWNER>
        assert!(exists<HISTORICAL_DATA>(OWNER), count);
        let database = borrow_global<HISTORICAL_DATA>(OWNER);    
        let data = vector::borrow(&database.database, count);

        //nacteni ulozenych dat do datoveho structu, ke kteremu patri
        let _data = DATA{
            userID: data.userID,
            txID: data.txID,
            timestamp: data.timestamp,
            number: data.number,
            number2: data.number2,
        };

        //debug
        print(&_data);
        //return
        move _data
    }

    #[view]
    public fun view_USER_TRANSACTIONS(userID: u64): vector<DATA> acquires USER_TRANSACTIONS_DATABASE {
        let tx_database = borrow_global<USER_TRANSACTIONS_DATABASE>(OWNER);
        let transactions = *table::borrow(&tx_database.transactions, userID);
        move transactions
    }


    #[view]
    public fun viewTotalDATA(): TOTAL acquires TOTAL {
        let total_stats = borrow_global<TOTAL>(OWNER);

        let _total_stats = TOTAL{
            totalTX: total_stats.totalTX,
            totalUsers: total_stats.totalUsers,
        };
        move _total_stats
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


    #[view]
    public fun view_USER_STATS(userID: u64): USER_DATA acquires USER_DATABASE {
        let userTable = borrow_global<USER_DATABASE>(OWNER);
        assert!(table::contains(&userTable.users, userID), ERROR_VAR_NOT_INITIALIZED);
        let user_data = *table::borrow(&userTable.users, userID);

        let _user_data = USER_DATA{
            id: user_data.id,
            creation: user_data.creation,
            totalTX: user_data.totalTX,
        };
        print(&_user_data);
        move _user_data
    }

 
    // Test function
    #[test(account = @0x1, owner = @0xc698c251041b826f1d3d4ea664a70674758e78918938d1b3b237418ff17b4020)]
    public entry fun test(account: signer, owner: signer) acquires DATA, HISTORICAL_DATA, USER_TRANSACTIONS_DATABASE, USER_DATABASE, TOTAL{
        timestamp::set_time_has_started_for_testing(&account);  
        print(&utf8(b" Executing storeDATA..."));
        storeDATA(&owner, 0 ,5,2);
        print(&utf8(b" Executing storeDATA..."));
        storeDATA(&owner, 0 ,5,2);
        print(&utf8(b" Executing storeDATA..."));
        storeDATA(&owner, 0 ,5,2);
        print(&utf8(b"First transaction... (viewDATA)"));
        viewDATA(0);
        print(&utf8(b" Executing storeDATA..."));
        storeDATA(&owner, 1,50,20);
        print(&utf8(b"View of all stored DATA... (viewALLDATA)"));
        viewALLDATA();
        print(&utf8(b"Data of user with ID 0... (view_USER_STATS)"));
        view_USER_STATS(0);
        print(&utf8(b"Total Stats... (viewTotalDATA)"));
        let viewTotalDATA = viewTotalDATA();
        print(&viewTotalDATA);
        print(&utf8(b" All stored data of user with ID 1 ... (view_USER_TRANSACTIONS)"));
        let viewUserTX = view_USER_TRANSACTIONS(0);
        print(&viewUserTX);
    }
}

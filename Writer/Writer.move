module deployer::BitcoinOracle{
  
    use std::signer;
    use std::vector;
    use std::account;
    use std::string;
    use std::timestamp;
    use std::table;
    use std::debug::print;
    use 0x8480994b8cdeb0b3c6136dcc65edaafd6cd4ad18eb0d515676f3efd4dbd7d5e5::BitcoinOracle;
    use 0x8480994b8cdeb0b3c6136dcc65edaafd6cd4ad18eb0d515676f3efd4dbd7d5e5::EthereumOracle;
    use 0x8480994b8cdeb0b3c6136dcc65edaafd6cd4ad18eb0d515676f3efd4dbd7d5e5::SolanaOracle;

    const OWNER: address = @0x8480994b8cdeb0b3c6136dcc65edaafd6cd4ad18eb0d515676f3efd4dbd7d5e5;


    // ERROR CODES
    const ERROR_NOT_VALIDATOR: u64 = 1;



    public entry fun Write(address: &signer, priceBTC: u64, priceETH: u64, priceSOL:) acquires DATA, HISTORICAL_DATA, COUNTER, VALIDATOR
    {

        let addr = signer::address_of(address);
        let btc_validator = BitcoinOracle::viewVALIDATOR();
        let eth_validator = EthereumOracle::viewVALIDATOR();
        let sol_validator = SolanaOracle::viewVALIDATOR();

        if(addr != btc_validator) {
            abort(ERROR_NOT_VALIDATOR)
        }
        else {
            BitcoinOracle::StoreData(address,priceBTC);
        }

        if(addr != eth_validator) {
            abort(ERROR_NOT_VALIDATOR)
        }
        else {
            EthereumOracle::StoreData(address,priceETH);
        }
   

        if(addr != sol_validator) {
            abort(ERROR_NOT_VALIDATOR)
        }
        else {
            SolanaOracle::StoreData(address,priceSOL);
        }
   
   
    }

 
    // Test function
    #[test(account = @0x1, owner = @0xc698c251041b826f1d3d4ea664a70674758e78918938d1b3b237418ff17b4020)]
    public entry fun test(account: signer, owner: signer) acquires DATA, HISTORICAL_DATA, COUNTER, CONFIG, VALIDATOR{
        init_module(&owner);
        Write(&owner, 5000,100,5000);
    }
}
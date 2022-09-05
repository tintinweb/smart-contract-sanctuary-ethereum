/**
 *Submitted for verification at Etherscan.io on 2022-09-05
*/

abstract contract cryptoKittiesInterface{
    function get() public virtual view returns(uint AGE);
    function set(uint _age) public virtual;
}

contract sobi {
    address a = 0x8Ac8CF96e4CFC5C206d764A9b7447812E5B36a37; //first deploy the cryptoKitties contract and paste the contract address over here 

    cryptoKittiesInterface object = cryptoKittiesInterface(a);

    function getfromInterface(uint y) public  returns(uint){
        object.set(y);
        return object.get();
    }
}
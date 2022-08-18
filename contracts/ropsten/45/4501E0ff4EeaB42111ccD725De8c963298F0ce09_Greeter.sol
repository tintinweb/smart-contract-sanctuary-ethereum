//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Greeter {

    address owner;
    struct list{
       string[] list_; 
    }
    struct address_st{
        address add;
        bool issale;
        uint256 price;
    }
    address_st new_address_st;

    mapping ( string => address_st ) registry;
    mapping (address => list) reverse_re;
    constructor() {
        owner = msg.sender;
        registerdomains();
    }

    function registerdomains() public{
        new_address_st.add = 0x8Ae2f6061dd2dEAbfB1F5062220Cdb7e6c5aDc87;
        registry['carinsurance.0x'] = new_address_st;
        registry['vacationrentals.0x'] = new_address_st;
        registry['cryptopayments.0x'] = new_address_st;
        registry['weddingplanner.0x'] = new_address_st;
        registry['digitalmarketing.0x'] = new_address_st;
        registry['freepornsites.0x'] = new_address_st;
        registry['financepartner.0x'] = new_address_st;
        registry['unpluggedmusic.0x'] = new_address_st;
        registry['hollywoodavatars.0x'] = new_address_st;

        reverse_re[0x8Ae2f6061dd2dEAbfB1F5062220Cdb7e6c5aDc87].list_.push('carinsurance.0x');
        reverse_re[0x8Ae2f6061dd2dEAbfB1F5062220Cdb7e6c5aDc87].list_.push('vacationrentals.0x');
        reverse_re[0x8Ae2f6061dd2dEAbfB1F5062220Cdb7e6c5aDc87].list_.push('cryptopayments.0x');
        reverse_re[0x8Ae2f6061dd2dEAbfB1F5062220Cdb7e6c5aDc87].list_.push('weddingplanner.0x');
        reverse_re[0x8Ae2f6061dd2dEAbfB1F5062220Cdb7e6c5aDc87].list_.push('digitalmarketing.0x');
        reverse_re[0x8Ae2f6061dd2dEAbfB1F5062220Cdb7e6c5aDc87].list_.push('freepornsites.0x');
        reverse_re[0x8Ae2f6061dd2dEAbfB1F5062220Cdb7e6c5aDc87].list_.push('financepartner.0x');
        reverse_re[0x8Ae2f6061dd2dEAbfB1F5062220Cdb7e6c5aDc87].list_.push('unpluggedmusic.0x');
        reverse_re[0x8Ae2f6061dd2dEAbfB1F5062220Cdb7e6c5aDc87].list_.push('hollywoodavatars.0x');

        new_address_st.add = 0x266F33E370C1aC53D57B299CCFfc64b6E224c2a9;
        registry['insurance.0x'] = new_address_st;
        reverse_re[0x266F33E370C1aC53D57B299CCFfc64b6E224c2a9].list_.push('insurance.0x');

    }

    function addNameToRegistry(string memory name) public payable {
        uint len = bytes(name).length;
        len -= 3;
        uint temp = 10;
        for (uint index = 0; index < len - 1; index++) {
            temp /= 2;
        }
        temp*=1000000000000000000;
        require(temp<=msg.value);
        if(registry[name].issale){
            for (uint256 i = 0; i < reverse_re[registry[name].add].list_.length; i++) {
                if(keccak256(abi.encodePacked((reverse_re[registry[name].add].list_[i]))) == keccak256(abi.encodePacked((name)))){
                    reverse_re[registry[name].add].list_[i] = 
                    reverse_re[registry[name].add].list_[reverse_re[registry[name].add].list_.length-1];
                    reverse_re[registry[name].add].list_.pop();
                    break;
                }
            }
            address payable to = payable(registry[name].add);
            to.transfer(msg.value * 99 / 100);        
        }

        new_address_st.add = msg.sender;
        registry[name] = new_address_st;

        reverse_re[msg.sender].list_.push(name);

        
    }

    function prepare_sale(string memory name, uint256 _price) public{
        require(msg.sender == registry[name].add);
        registry[name].issale = true;
        registry[name].price = _price;
    }

    function registryIsPossible(string memory name) public view returns(uint){
        if(registry[name].add == address(0x0))
            return 0;
        if(registry[name].issale)
            return 1;        
        else return 2;
    }

    function getPrice(string memory name)public view returns(uint256){
        return registry[name].price;
    }

    function getUser(string memory name) public view returns(address) {
        return registry[name].add;
    }

    function getOwner() public view returns(address) {
        return owner;
    }

    function getissale(string memory name) public view returns(bool){
        return registry[name].issale;
    }

    function getNames(address currentUser) public view returns(string[] memory) {
        return reverse_re[currentUser].list_;
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function withdrawMoney() public {
        address payable to = payable(owner);
        to.transfer(getBalance());
    }

    function transferOwnership(address newOwner) public {
        require(msg.sender == owner);
            owner = newOwner;
    }

}
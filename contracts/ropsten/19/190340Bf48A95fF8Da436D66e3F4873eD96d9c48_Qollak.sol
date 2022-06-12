// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Qollak {

    event KidAdded(address parentWalletAddress, address kidWalletAddress, uint amount, uint contractBalance);
    event KidCharged(address parentWalletAddress, address kidWalletAddress, uint amount, uint contractBalance);


    struct Kid {
        address payable walletAddress;
        string name;
        uint releaseTime;
        uint amount;
        bool broken;
    }

    address[] private parents;
    mapping(address => mapping(uint => Kid)) public kids;
    mapping(address => uint) private kidsCount;

    function getKidsCount() private view returns(uint){
        return kidsCount[msg.sender];
    }

    // get kid methods
    function getKidByAddress(address kidWalletAddress) public view returns(Kid memory kid, uint index){
        for (uint i = 0; i < getKidsCount(); i++){
            if (kids[msg.sender][i].walletAddress == kidWalletAddress){
                kid = kids[msg.sender][i];
                index = i;
            }
        }
    }
 
    function getMe() public view returns(Kid memory kid, address parent, int index){
        index = -1;
        for (uint i = 0; i < parents.length; i++){
            address _parent = parents[i];
            for (uint j=0; j < kidsCount[_parent]; j++){
                if (kids[_parent][j].walletAddress == msg.sender){
                    kid = kids[_parent][j];
                    parent = _parent;
                    index = int(j);
                }   
            }
        }
    }

    function getKids() public view returns(Kid[] memory){
        Kid[] memory _kids = new Kid[](getKidsCount());
        for (uint i = 0; i < getKidsCount(); i++) {
            _kids[i] = kids[msg.sender][i];
        }
        return _kids;
    }

    // check kid existance
    modifier kidExist(address kidWalletAddress){
        (Kid memory _kid,) = getKidByAddress(kidWalletAddress);
        require(_kid.walletAddress == address(0), "Kid Exist!");
        _;
    }
    modifier kidNotExist(address kidWalletAddress){
        (Kid memory _kid,) = getKidByAddress(kidWalletAddress);
        require(_kid.walletAddress != address(0), "Kid Not Exist!");
        _;
    }

    // create Qollak for kid
    function addKid(address payable kidWalletAddress, string memory name, uint releaseTime) payable public kidExist(kidWalletAddress){
        kids[msg.sender][getKidsCount()]= Kid(
            kidWalletAddress,
            name,
            releaseTime,
            msg.value,
            false
        );
        if (getKidsCount() == 0){
            parents.push(msg.sender);
        }
        kidsCount[msg.sender] += 1;

        emit KidAdded(msg.sender, kidWalletAddress, msg.value, balanceOf());
    }

    function balanceOf() public view returns(uint) {
        return address(this).balance;
    }

    // add fund to kid's Qollak
    function depositForKid(address walletAddress) payable public kidNotExist(walletAddress){
        addToKidsQollak(walletAddress);
    }

    function addToKidsQollak(address kidWalletAddress) private {
        (, uint _index) = getKidByAddress(kidWalletAddress);
        kids[msg.sender][_index].amount += msg.value;
        emit KidCharged(msg.sender, kidWalletAddress, msg.value, balanceOf());
    }


    // check release time
    function canBreak() public view returns(bool) {
        (Kid memory _kid, ,int _index) = getMe();
        require(_index != -1 , "You don't have Qollak!");
        require(_kid.broken == false, "Already broken!");
        // require(block.timestamp > _kid.releaseTime, "You can't break yet!");
        if (block.timestamp > _kid.releaseTime) {
            return true;
        } else {
            return false;
        }
    }

    // break the Qollak
    function breakMyQollak() payable public {
        (Kid memory _kid, address _parent, int _index) = getMe();
        require(msg.sender == _kid.walletAddress, "You must be the kid to break the Qollak!");
        require(_kid.broken == false, "Already broken!");
        _kid.walletAddress.transfer(_kid.amount);
        kids[_parent][uint(_index)].broken = true;
    }

}
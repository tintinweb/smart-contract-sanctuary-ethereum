// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./IterableMapping.sol";

contract PureNFT {
    using IterableMapping for itmap;

    address private constant ADDRESS_NULL = address(0x0);
    address private _contractOwner;

    enum nNftState {
        Active,
        Inactive
    }

    struct nNft {
        itmap owners; //mapping between address and %percentatge
        string hashFile;
        string uriFile;
        string hashMetaFile;
        string uriMetaFile;
        uint256 price;
        string uriLicense;
        string copyright;
        nNftState state;
    }

    mapping(string => nNft) private _UsersWithNfts;

    uint256 private _counter;

    event ContractSetupCompleted(address owner);
    event Minted(address owner, string token);
    event Transfered(
        string token,
        uint256 percentatge,
        address from,
        uint256 newFromPercentatge,
        address to,
        uint256 newToPercentate
    );
    event Sold(
        address buyer,
        string token,
        uint256 amount,
        string newLicense,
        string newCopyright
    );


    event SoldOne(address buyer, string token, uint256 amount);
    event DisabledToken(string token);
    event EnabledToken(string token);
    event Withdrawn(address seller, uint256 amount);
    event WithdrawnRemainFail(address, uint256);
    event FoundsReceived(address, uint256);
    /// the funds send don't cover the price
    error NotEnoughMoney(string);
    // // The function cannot be called at the current state.
    //error InvalidState();
    /// Not an owner of a token
    error NoOwner();
    /// No funds to be withdrawn
    error NoMoneyToWithdraw();
    /// Error getting funds
    error WithdrawCancelled(address, uint256);

    constructor() {
        //require(_contractOwner != address(0), "Master address cannot be a zero address");

        _contractOwner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        _counter = 0;

        emit ContractSetupCompleted(_contractOwner);
    }

    modifier isOwner() {
        require(msg.sender == address(_contractOwner), "Caller is not owner");
        _;
    }

    /*
    modifier inState(nNft storage nft, nNftState state_) {
        if (nft.state != state_)
            revert InvalidState();
        _;
    }*/

    function mint(
        address to,
        string memory token,
        string memory uriFile,
        string memory hashFile,
        string memory uriMetaInfo,
        string memory hashMetaInfo,
        uint256 price,
        string memory uriLicense,
        string memory copyright
    ) public isOwner returns (bool) {
        require(to != ADDRESS_NULL, "No null address is allowed");
        require(bytes(token).length != 0, "token is mandatory");
        require(bytes(uriFile).length != 0, "uriFile is mandatory");
        require(bytes(hashFile).length != 0, "hashFile is mandatory");
        require(bytes(uriMetaInfo).length != 0, "uriMetaInfo is mandatory");
        require(bytes(hashMetaInfo).length != 0, "hashMetaInfo is mandatory");
        require(bytes(uriLicense).length != 0, "uriLicense is mandatory");
        require(bytes(copyright).length != 0, "copyright is mandatory");
        require(price >= 100, "price must be >=100 wei");
        require(price % 2 == 0, "price must be even");
        require(
            bytes(_UsersWithNfts[token].hashFile).length == 0,
            "token in use"
        );

        _UsersWithNfts[token].owners.insert(_contractOwner, 30, 0);
        _UsersWithNfts[token].owners.insert(to, 70, 0);

        _UsersWithNfts[token].hashFile = hashFile;
        _UsersWithNfts[token].uriFile = uriFile;
        _UsersWithNfts[token].hashMetaFile = hashMetaInfo;
        _UsersWithNfts[token].uriMetaFile = uriMetaInfo;
        _UsersWithNfts[token].uriLicense = uriLicense;
        _UsersWithNfts[token].copyright = copyright;
        _UsersWithNfts[token].price = price;
        _UsersWithNfts[token].state = nNftState.Active;

        _counter++;

        emit Minted(to, token);

        return true;
    }

    function getStateName(nNftState state) internal pure returns (string memory) {
        if (state == nNftState.Active) return "Active";
        if (state == nNftState.Inactive) return "Inactive";
        return "";
    }

    // returns (nNft memory)
    function getContentByToken(string memory token)
        public
        view
        returns (
            string memory uriFile,
            string memory hashFile,
            string memory uriMetaFile,
            string memory hashMetaFile,
            string memory uriLicense,
            string memory copyright,
            uint256 price,
            string memory state
        )
    {
        require(bytes(token).length != 0, "token is mandatory");
        require(
            bytes(_UsersWithNfts[token].hashFile).length != 0,
            "token doesn't exist"
        );
        nNft storage nft = _UsersWithNfts[token];
        string memory sts= getStateName(_UsersWithNfts[token].state);
        return (
            nft.uriFile,
            nft.hashFile,
            nft.uriMetaFile,
            nft.hashMetaFile,
            nft.uriLicense,
            nft.copyright,
            nft.price,
            sts 
        );
    }

    struct Ownership {
        address owner;
        uint256 percentatge;
    }

    function getOnwersByToken(string memory token)
        public
        view
        returns (Ownership[] memory)
    {
        require(bytes(token).length != 0, "token is mandatory");
        require(
            bytes(_UsersWithNfts[token].hashFile).length != 0,
            "token doesn't exist"
        );
        uint256 total = _UsersWithNfts[token].owners.size;
        Ownership[] memory ownees = new Ownership[](total);

        itmap storage data = _UsersWithNfts[token].owners;
        uint256 counter = 0;
        for (
            Iterator i = data.iterateStart();
            data.iterateValid(i);
            i = data.iterateNext(i)
        ) {
            (address key, uint256 percentatge, ) = data.iterateGet(i);
            ownees[counter].owner = key;
            ownees[counter].percentatge = percentatge;
            counter++;
        }

        return (ownees);
    }

    struct Withdrawship {
        address owner;
        uint256 amount;
        uint256 percentatge;
    }

    function getPendingWithdrawsByToken(string memory token)
        public
        view
        isOwner
        returns (Withdrawship[] memory)
    {
        require(bytes(token).length != 0, "token is mandatory");
        require(
            bytes(_UsersWithNfts[token].hashFile).length != 0,
            "token doesn't exist"
        );
        uint256 total = _UsersWithNfts[token].owners.size;
        Withdrawship[] memory balances = new Withdrawship[](total);

        itmap storage data = _UsersWithNfts[token].owners;
        uint256 counter = 0;
        for (
            Iterator i = data.iterateStart();
            data.iterateValid(i);
            i = data.iterateNext(i)
        ) {
            (address key, uint256 percentatge, uint256 balance) = data
                .iterateGet(i);
            balances[counter].owner = key;
            balances[counter].amount = balance;
            balances[counter].percentatge = percentatge;
            counter++;
        }

        return (balances);
    }

    function getWithdrawsAvailableByToken(string memory token)
        public
        view
        returns (uint256 funds)
    {
        require(bytes(token).length != 0, "token is mandatory");
        require(
            bytes(_UsersWithNfts[token].hashFile).length != 0,
            "token doesn't exist"
        );
        funds = 0;
        address owner = msg.sender;

        nNftOwner memory aux = _UsersWithNfts[token].owners.data[owner].value;
        if (aux.amountToWithdraw != 0) {
            funds = aux.amountToWithdraw;
        }

        return funds;
    }

    function getTotalMinted() public view isOwner returns (uint256) {
        return _counter;
    }

    function transferOwnership(
        address from,
        string memory token,
        address to,
        uint256 percentatge
    ) public isOwner returns (bool) {
        require(to != address(0), "No null to address is allowed");
        require(from != address(0), "No null from address is allowed");
        require(
            from != to,
            "source address must be differnt to destination address"
        );
        require(bytes(token).length != 0, "token is mandatory");
        require(percentatge <= 100, "percentatge isn't correct, must be between 1 and 100");
        require(percentatge > 0, "percentatge isn't correct, must be between 1 and 100");
        require(
            bytes(_UsersWithNfts[token].hashFile).length != 0,
            "token doesn't exist"
        );
        require(
            _UsersWithNfts[token].owners.contains(from),
            "from address must be among the owners"
        );
        require(
            _UsersWithNfts[token].owners.contains(to),
            "to address must be among the owners"
        );
        require(
            _UsersWithNfts[token].owners.data[from].value.percentatge >=
                percentatge,
            //_UsersWithNfts[token].owners[from].value >= percentatge,
            "from address has no enought ownership"
        );
        require(
            _UsersWithNfts[token].owners.data[to].value.percentatge +
                percentatge <=
                100,
            //_UsersWithNfts[token].owners[to].value.percentatge + percentatge <= 100,
            "destination address would have more than 100% ownership, impossible!"
        );
        /*require(
            _UsersWithNfts[token].state  == nNftState.Trading ,
            "token state doesn't allow it"
        );*/

        _UsersWithNfts[token]
            .owners
            .data[from]
            .value
            .percentatge -= percentatge;
        _UsersWithNfts[token].owners.data[to].value.percentatge += percentatge;

        emit Transfered(
            token,
            percentatge,
            from,
            _UsersWithNfts[token].owners.data[from].value.percentatge,
            to,
            _UsersWithNfts[token].owners.data[to].value.percentatge
        );
        return true;
    }

    receive() external payable {
        emit FoundsReceived(msg.sender, msg.value);
    }

    function getBallance() public view isOwner returns (uint256) {
        return address(this).balance;
    }

    function buy(
        string memory token,
        string memory newLicence,
        string memory newCopyright,
        uint256 newPrice
    ) public payable {
        require(bytes(token).length != 0, "token is mandatory");
        require(
            bytes(_UsersWithNfts[token].hashFile).length != 0,
            "token doesn't exist"
        );
        require(bytes(newCopyright).length != 0, "new copyright is mandatory");
        require(
            _UsersWithNfts[token].state  == nNftState.Active,
            "token state doesn't allow it"
        );
        require(
            !_UsersWithNfts[token].owners.contains(msg.sender),
            "you're already an owner"
        );

        address buyer = payable(msg.sender);

        //buyer transfer money to contract
        uint256 deposit = msg.value;

        if (deposit < _UsersWithNfts[token].price) {
            revert NotEnoughMoney("buyer has not enought money");
        }
        uint256 totalPayed = 0;
        itmap storage data = _UsersWithNfts[token].owners;

        for (
            Iterator i = data.iterateStart();
            data.iterateValid(i);
            i = data.iterateNext(i)
        ) {
            (, uint256 percent, ) = data.iterateGet(i);
            if (percent > 0) {
                uint256 amountToWithdraw = (deposit / 100) * percent;
                data.update(i, 0, amountToWithdraw);
                totalPayed += amountToWithdraw;
            }
        }

        // in case % has decimals and remains some budget, then send it to the contract
        uint256 remain = deposit - totalPayed;

        if (remain > 0) {
            (bool sent, ) = payable(_contractOwner).call{value: remain}("");
            if (!sent) {
                emit WithdrawnRemainFail(_contractOwner, remain);
            }
        }

        _UsersWithNfts[token].owners.insert(msg.sender, 100, 0);
        _UsersWithNfts[token].uriLicense = newLicence;
        _UsersWithNfts[token].copyright = newCopyright;
        _UsersWithNfts[token].price = newPrice;

        emit Sold(buyer, token, deposit, newLicence, newCopyright);
    }

    function withdraw(string memory token) public payable {
        require(bytes(token).length != 0, "token is mandatory");
        require(
            bytes(_UsersWithNfts[token].hashFile).length != 0,
            "token doesn't exist"
        );

        address owner = msg.sender;

        (bool found, Iterator i) = _UsersWithNfts[token].owners.find(owner);

        if (!found) {
            revert NoOwner();
        }

        (, uint256 percent, uint256 amount) = _UsersWithNfts[token]
            .owners
            .iterateGet(i);

        if (amount == 0) {
            revert NoMoneyToWithdraw();
        }

        //payable(owner).transfer(amount);
        (bool sent, ) = payable(owner).call{value: amount}("");
        if (sent) {
            _UsersWithNfts[token].owners.update(i, percent, 0);
            emit Withdrawn(owner, amount);
        } else {
            revert WithdrawCancelled(owner, amount);
        }
    }

    function disableByToken(string memory token) public isOwner {
        _UsersWithNfts[token].state = nNftState.Inactive;
        emit DisabledToken(token);
    }
    function enableByToken(string memory token) public isOwner {
        _UsersWithNfts[token].state = nNftState.Active;
        emit EnabledToken(token);
    }

}

// SPDX-License-Identifier: GPL-3.0
// pragma solidity ^0.8.8;
pragma solidity >=0.8.8 <0.9.0;

struct nNftOwner {
    //address owner;
    uint    percentatge;
    uint    amountToWithdraw;    
}


struct IndexValue { uint keyIndex; nNftOwner value; }
struct KeyFlag { address key; bool deleted; }

struct itmap {
    mapping(address => IndexValue) data;
    KeyFlag[] keys;
    uint size;
}

type Iterator is uint;

library IterableMapping {

    bytes32 constant NULL = "";

    function insert(itmap storage self, address key, uint percent, uint amount) internal returns (bool replaced) {
        uint keyIndex = self.data[key].keyIndex;
        self.data[key].value.percentatge = percent;
        self.data[key].value.amountToWithdraw = amount;
        if (keyIndex > 0)
            return true;
        else {
            keyIndex = self.keys.length;
            self.keys.push();
            self.data[key].keyIndex = keyIndex + 1;
            self.keys[keyIndex].key = key;
            self.size++;
            return false;
        }
    }

    function remove(itmap storage self, address key) internal returns (bool success) {
        uint keyIndex = self.data[key].keyIndex;
        if (keyIndex == 0)
            return false;
        delete self.data[key];
        self.keys[keyIndex - 1].deleted = true;
        self.size --;
    }

    function contains(itmap storage self, address key) internal view returns (bool) {
        return self.data[key].keyIndex > 0;
    }

    function iterateStart(itmap storage self) internal view returns (Iterator) {
        return iteratorSkipDeleted(self, 0);
    }

    function iterateValid(itmap storage self, Iterator iterator) internal view returns (bool) {
        return Iterator.unwrap(iterator) < self.keys.length;
    }

    function iterateNext(itmap storage self, Iterator iterator) internal view returns (Iterator) {
        return iteratorSkipDeleted(self, Iterator.unwrap(iterator) + 1);
    }

    function iterateGet(itmap storage self, Iterator iterator) internal view returns (address key, uint percent, uint amount) {
        uint keyIndex = Iterator.unwrap(iterator);
        key = self.keys[keyIndex].key;
        percent = self.data[key].value.percentatge;
        amount = self.data[key].value.amountToWithdraw;
    }
    
    function update(itmap storage self, Iterator iterator, uint percent, uint amount) internal {
        uint keyIndex = Iterator.unwrap(iterator);
        address key = self.keys[keyIndex].key;
        self.data[key].value.percentatge = percent;
        self.data[key].value.amountToWithdraw = amount;
    }

    function find(itmap storage self, address key) internal view returns (bool, Iterator) {
       uint foundKeyIndex=0;
       bool foundFlag = false;
       for(uint i=0; i< self.size && !foundFlag; i++) {
            address aux = self.keys[i].key;
            if(aux == key){
                foundKeyIndex=i;
                foundFlag= true;
            }
       }
       return (foundFlag, iteratorSkipDeleted(self,foundKeyIndex));
    }

    function iteratorSkipDeleted(itmap storage self, uint keyIndex) private view returns (Iterator) {
        while (keyIndex < self.keys.length && self.keys[keyIndex].deleted)
            keyIndex++;
        return Iterator.wrap(keyIndex);
    }

}
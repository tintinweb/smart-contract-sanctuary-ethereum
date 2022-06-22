/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

pragma solidity ^0.8.0;
//SPDX-License-Identifier: UNLICENSED

contract Library {

    struct data {
        uint256 tradeCount;
        uint256 tradeRec;
    }
    struct users {
        string id;
        address payable wallet;
        bool isValid;
        uint256[] timeIndex;
        data userData;
    }
    struct itemIndex {
        address buyerAddr;
        uint256 timestamp;
    }
    struct seller {
        users user;
        itemIndex[] buyerIndex;
    }
    struct arbiter {
        users user;
        itemIndex[] publicIndex;
        itemIndex[] privateIndex;
        uint256 stakingBalance;
        string message;
    }
    struct judgement {
        uint256 buyerTotalScore;
        address[] buyerSup;
        uint256[] buyerScore;
        uint256 sellerTotalScore;
        address[] sellerSup;
        uint256[] sellerScore;
        uint256 itemTotalStaking;
        uint256 deadline;
    }
    struct ipfsHash {
        string picture;
        string moreMsg;
    }
    struct itemInfo {
        string name;
        uint256 price;
        uint256 number;
        uint256 arrivalTime;
        ipfsHash hash;
    }
    struct publicItems {
        itemInfo item;
        address payable sellerAddr;
        uint256 listTime;
        string message;
    }
    struct privateItems {
        publicItems publicItem;
        address payable buyerAddr;
        judgement itemJudgement;
    }

    function deleteItem(uint256[] storage _array, uint256 _item)
    internal {
        require(_array.length > 0);
        if(_array.length == 1) {
            _array.pop();
        }
        else {
            for(uint i = 0; i < _array.length; i++) {
                if(_array[i] == _item) {
                    _array[i] = _array[_array.length-1];
                    _array.pop();
                    break;
                }
            }
        }
    }
    function deleteStruct(itemIndex[] storage _itemArray, itemIndex memory _item)
    internal {
        require(_itemArray.length > 0);
        if(_itemArray.length == 1) {
            _itemArray.pop();
        }
        else {
            for(uint i = 0; i < _itemArray.length; i++) {
                if(_itemArray[i].buyerAddr == _item.buyerAddr && _itemArray[i].timestamp == _item.timestamp) {
                    _itemArray[i] = _itemArray[_itemArray.length-1];
                    _itemArray.pop();
                    break;
                }
            }
        }
    }
    function checkSup(privateItems memory targetItems, address _arbiterAddr, uint256 _buyerSupCount, uint256 _sellerSupCount)
    internal pure returns(bool) {
        uint256 flagBuyer = 0; uint256 flagSeller = 0;
        for(uint256 i = 0; i < _buyerSupCount; i++) {
            if(targetItems.itemJudgement.buyerSup[i] == _arbiterAddr) {
                flagBuyer = 1;
                break;
            }
        }
        for(uint256 i = 0; i < _sellerSupCount; i++) {
            if(targetItems.itemJudgement.sellerSup[i] == _arbiterAddr) {
                flagSeller = 1;
                break;
            }
        }
        if(flagBuyer == 0 && flagSeller == 0) {
            return true;
        }
        else {
            return false;
        }
    }
}

contract ERC20Token {
    string public symbol;
    string public name;
    uint8 public decimals;
    uint _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    constructor(string memory _name, string memory _symbol, uint _total, uint _decimals) {
        symbol = _symbol;
        name = _name;
        _totalSupply = _total * 10**uint(_decimals);
        balances[address(this)] = _totalSupply;
    }

    function totalSupply()
    public view returns (uint) {
        return _totalSupply-balances[address(0)];
    }

    function balanceOf(address tokenOwner)
    public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens)
    public returns (bool success) {
        balances[msg.sender] = balances[msg.sender]-tokens;
        balances[to] = balances[to]+tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint tokens)
    public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    function transferFromContract(address to, uint tokens)
    internal returns (bool success) {
        balances[address(this)] = balances[address(this)]-tokens;
        balances[to] = balances[to]+tokens;
        emit Transfer(address(this), to, tokens);
        return true;
    }
    function transferFrom(address from, address to, uint tokens)
    public returns (bool success) {
        balances[from] = balances[from]-tokens;
        allowed[from][msg.sender] = allowed[from][msg.sender]-tokens;
        balances[to] = balances[to]+tokens;
        emit Transfer(from, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender)
    public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    receive ()
    external payable {
        revert();
    }
}

contract Marketplace is ERC20Token, Library {
    uint256 public rewardTime;
    uint8 public rewardRate;
    uint256 public weekItemCount;
    uint256 lastWeekItemCount;
    uint256 totalStakingBalance;
    mapping(address => mapping(uint256 => publicItems)) sellerBoard;
    mapping(address => mapping(uint256 => privateItems)) buyerBoard;
    mapping(address => users)Buyer;
    mapping(address => seller)Seller;
    mapping(address => arbiter)Arbiter;
    mapping(uint256 => publicItems) marketBoard;
    uint256[] marketIndex;
    arbiter[] arbiterMarketBoard;
    address contractOwner;
    
    constructor() ERC20Token("NDHU Token", "NDHU", 1000000000, 1) {
        contractOwner = msg.sender;
        rewardTime = block.timestamp + 7 * 1 days;
    }

    fallback()
    external payable {
        revert();
    }

    modifier unSignUp {
        require(Buyer[msg.sender].isValid == false);
        _;
    }

    function changeRewardRate()
    internal {
        weekItemCount++;
        if(block.timestamp >= rewardTime) {
            if(weekItemCount > 2*lastWeekItemCount && rewardRate < 10) {
                rewardRate += 1;
            }
            else if(2*weekItemCount < lastWeekItemCount && rewardRate > 0) {
                rewardRate -= 1;
            }
            rewardTime = block.timestamp + 7 * 1 days;
            lastWeekItemCount = weekItemCount;
            weekItemCount = 0;
        }
    }

    function signUp(string memory id)
    external unSignUp {
        require(Buyer[msg.sender].isValid == false);
        Buyer[msg.sender].id = id;
        Buyer[msg.sender].wallet = payable(msg.sender);
        Buyer[msg.sender].isValid = true;
        Seller[msg.sender].user = Buyer[msg.sender];
    }

    function beArbiter()
    external {
        require(Buyer[msg.sender].isValid == true && Arbiter[msg.sender].user.isValid == false);
        Arbiter[msg.sender].user.isValid == true;
        Arbiter[msg.sender].user = Buyer[msg.sender];
        delete Arbiter[msg.sender].user.timeIndex;
        Arbiter[msg.sender].user.userData = data(2, 1);
        arbiterMarketBoard.push(Arbiter[msg.sender]);
    }

    function stakeToken(uint256 _amount)
    external {
        require(ERC20Token.balanceOf(msg.sender) >= _amount);
        ERC20Token.transfer(address(this), _amount);
        Arbiter[msg.sender].stakingBalance += _amount;
        totalStakingBalance += _amount;
    }

    function unstakeToken(uint256 _amount)
    external {
        require(_amount <= Arbiter[msg.sender].stakingBalance);
        ERC20Token.transferFromContract(msg.sender, _amount);
        Arbiter[msg.sender].stakingBalance -= _amount;
        totalStakingBalance -= _amount;
    }

    function list(string memory _name, uint256 _price, string memory _unit, uint256 _number, string memory _message, uint256 _time, string memory _picture, string memory _moreMsg)
    external {
        require((keccak256(abi.encodePacked(_unit)) == keccak256(abi.encodePacked("ether")) || keccak256(abi.encodePacked(_unit)) == keccak256(abi.encodePacked("gwei"))) && marketBoard[block.timestamp].listTime == 0);
        _price *= (keccak256(abi.encodePacked(_unit))==keccak256(abi.encodePacked("ether"))) ? 1 ether : 1000000000;
        sellerBoard[msg.sender][block.timestamp] = publicItems(itemInfo(_name, _price, _number, _time * 1 days, ipfsHash(_picture, _moreMsg)), payable(msg.sender), block.timestamp, _message);
        marketBoard[block.timestamp] = sellerBoard[msg.sender][block.timestamp];
        marketIndex.push(block.timestamp);
        Seller[msg.sender].user.timeIndex.push(block.timestamp);
        if(rewardRate >= 5) {
            ERC20Token.transfer(address(this), (rewardRate-5)*2);
        }
    }

    function buy(address payable _sellerAddr, uint256 _sellerIndex, uint256 _number)
    external payable {
        require(_number <= sellerBoard[_sellerAddr][_sellerIndex].item.number && msg.sender != _sellerAddr && msg.value == sellerBoard[_sellerAddr][_sellerIndex].item.price * _number);
        buyerBoard[msg.sender][block.timestamp].publicItem = sellerBoard[_sellerAddr][_sellerIndex];
        buyerBoard[msg.sender][block.timestamp].publicItem.item.number = _number;
        buyerBoard[msg.sender][block.timestamp].buyerAddr = payable(msg.sender);
        Buyer[msg.sender].timeIndex.push(block.timestamp);
        Seller[_sellerAddr].buyerIndex.push(itemIndex(msg.sender, block.timestamp));
        sellerBoard[_sellerAddr][_sellerIndex].item.number -= _number;
        marketBoard[_sellerIndex].item.number = sellerBoard[_sellerAddr][_sellerIndex].item.number;
        if(sellerBoard[_sellerAddr][_sellerIndex].item.number == 0) {
            deleteItem(Seller[_sellerAddr].user.timeIndex, _sellerIndex);
            delete sellerBoard[_sellerAddr][_sellerIndex];
            delete marketBoard[_sellerIndex];
            deleteItem(marketIndex, _sellerIndex);
        }
    }

    function pay(uint256 _buyerIndex)
    external {
        address payable _sellerAddr = buyerBoard[msg.sender][_buyerIndex].publicItem.sellerAddr;
        _sellerAddr.transfer(buyerBoard[msg.sender][_buyerIndex].publicItem.item.price * buyerBoard[msg.sender][_buyerIndex].publicItem.item.number);
        if(rewardRate < 5) {
            ERC20Token.transferFromContract(_sellerAddr, 5-rewardRate);
            ERC20Token.transferFromContract(msg.sender, 5-rewardRate);
        }
        changeRewardRate();
        Buyer[msg.sender].userData.tradeCount += 1;
        Buyer[msg.sender].userData.tradeRec += 1;
        Seller[_sellerAddr].user.userData.tradeCount += 1;
        Seller[_sellerAddr].user.userData.tradeRec += 1;
        deleteStruct(Seller[_sellerAddr].buyerIndex, itemIndex(msg.sender, _buyerIndex));
        delete buyerBoard[msg.sender][_buyerIndex];
        deleteItem(Buyer[msg.sender].timeIndex, _buyerIndex);
    }

    function appeal(address _arbiterAddr, address payable _buyerAddr, uint256 _buyerIndex)
    external {
        address payable _sellerAddr = buyerBoard[_buyerAddr][_buyerIndex].publicItem.sellerAddr;
        require(msg.sender == _sellerAddr || msg.sender == _buyerAddr);
        if((block.timestamp <= buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.deadline || buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.deadline == 0) && checkSup(buyerBoard[_buyerAddr][_buyerIndex], _arbiterAddr, buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.buyerSup.length, buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.sellerSup.length)) {
            if(buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.deadline == 0) {
                buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.deadline = block.timestamp + 7 * 1 days;
                buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.buyerScore.push(0);
                buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.sellerScore.push(0);
            }
            uint256 _fee = 10+(10*(buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.buyerSup.length+buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.sellerSup.length));
            ERC20Token.transfer(address(this), _fee);
            if(msg.sender == _buyerAddr) {
                buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.buyerScore[0] += _fee;
            }
            else {
                buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.sellerScore[0] += _fee;
            }
            buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.itemTotalStaking += _fee;
            Arbiter[_arbiterAddr].publicIndex.push(itemIndex(_buyerAddr, _buyerIndex));
        }
        else if(block.timestamp > buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.deadline) {
            Buyer[_buyerAddr].userData.tradeCount += 1;
            Seller[_sellerAddr].user.userData.tradeCount += 1;
            if(buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.buyerTotalScore > buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.sellerTotalScore) {
                _buyerAddr.transfer(buyerBoard[_buyerAddr][_buyerIndex].publicItem.item.price * buyerBoard[_buyerAddr][_buyerIndex].publicItem.item.number);
                ERC20Token.transferFromContract(_buyerAddr, buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.buyerScore[0]);
                buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.itemTotalStaking -= buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.buyerScore[0];
                for(uint i = 0; i < buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.buyerSup.length; i++) {
                    Arbiter[buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.buyerSup[i]].stakingBalance += (buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.itemTotalStaking * buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.buyerScore[i+1] / buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.buyerTotalScore);
                    deleteStruct(Arbiter[buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.buyerSup[i]].privateIndex, itemIndex(_buyerAddr, _buyerIndex));
                }
                Buyer[_buyerAddr].userData.tradeRec += 1;
            }
            else if(buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.sellerTotalScore > buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.buyerTotalScore) {
                _sellerAddr.transfer(buyerBoard[_buyerAddr][_buyerIndex].publicItem.item.price * buyerBoard[_buyerAddr][_buyerIndex].publicItem.item.number);
                ERC20Token.transferFromContract(_sellerAddr, buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.sellerScore[0]);
                buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.itemTotalStaking -= buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.sellerScore[0];
                for(uint i = 0; i < buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.sellerSup.length; i++) {
                    Arbiter[buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.sellerSup[i]].stakingBalance += (buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.itemTotalStaking * buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.sellerScore[i+1] / buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.sellerTotalScore);
                    deleteStruct(Arbiter[buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.sellerSup[i]].privateIndex, itemIndex(_buyerAddr, _buyerIndex));
                }
                Seller[_sellerAddr].user.userData.tradeRec += 1;
            }
            else {
                _buyerAddr.transfer(buyerBoard[_buyerAddr][_buyerIndex].publicItem.item.price * buyerBoard[_buyerAddr][_buyerIndex].publicItem.item.number / 2);
                _sellerAddr.transfer(buyerBoard[_buyerAddr][_buyerIndex].publicItem.item.price * buyerBoard[_buyerAddr][_buyerIndex].publicItem.item.number / 2);
                for(uint i = 0; i < buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.buyerSup.length; i++) {
                    Arbiter[buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.buyerSup[i]].stakingBalance += (buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.itemTotalStaking * buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.buyerScore[i+1] /(buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.buyerTotalScore+buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.sellerTotalScore));
                    deleteStruct(Arbiter[buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.buyerSup[i]].privateIndex, itemIndex(_buyerAddr, _buyerIndex));
                }
                for(uint i = 0; i < buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.sellerSup.length; i++) {
                    Arbiter[buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.sellerSup[i]].stakingBalance += (buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.itemTotalStaking * buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.sellerScore[i+1] /(buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.buyerTotalScore+buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.sellerTotalScore));
                    deleteStruct(Arbiter[buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.sellerSup[i]].privateIndex, itemIndex(_buyerAddr, _buyerIndex));
                }
            }
            deleteStruct(Seller[_sellerAddr].buyerIndex, itemIndex(_buyerAddr, _buyerIndex));
            delete buyerBoard[_buyerAddr][_buyerIndex];
            deleteItem(Buyer[_buyerAddr].timeIndex, _buyerIndex);
        }
    }

    function arbiterAccept(uint256 _count, uint8 _accept, uint8 _buyerAppeal)
    external {
        address _buyerAddr = Arbiter[msg.sender].publicIndex[_count].buyerAddr;
        uint256 _buyerIndex =  Arbiter[msg.sender].publicIndex[_count].timestamp;
        require(block.timestamp <= buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.deadline && Arbiter[msg.sender].stakingBalance >= 10 && 
        checkSup(buyerBoard[_buyerAddr][_buyerIndex], msg.sender, buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.buyerSup.length, buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.sellerSup.length));

        if(_accept == 0) {
            Arbiter[msg.sender].privateIndex.push(Arbiter[msg.sender].publicIndex[_count]);
            uint256 _score = Arbiter[msg.sender].stakingBalance*(Arbiter[msg.sender].user.userData.tradeRec**5)/(Arbiter[msg.sender].user.userData.tradeCount**5);
            if(_buyerAppeal == 0) {
                buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.sellerSup.push(msg.sender);
                buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.sellerScore.push(_score);
                buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.sellerTotalScore += _score;
            }
            else {
                buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.buyerSup.push(msg.sender);
                buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.buyerScore.push(_score);
                buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.buyerTotalScore += _score;
            }
            Arbiter[msg.sender].stakingBalance -= Arbiter[msg.sender].stakingBalance/10;
            buyerBoard[_buyerAddr][_buyerIndex].itemJudgement.itemTotalStaking += (Arbiter[msg.sender].stakingBalance/10);
        }
        deleteStruct(Arbiter[msg.sender].publicIndex, itemIndex(_buyerAddr, _buyerIndex));
    }

    function changeArbiterMessage(string memory _messageHash)
    external {
        Arbiter[msg.sender].message = _messageHash;
    }

    function viewMarketBoard(uint256 _timestamp)
    external view returns (publicItems memory) {
        return marketBoard[_timestamp];
    }
    function viewMarketIndex(uint256 _count)
    external view returns (uint256, uint256) {
        return (marketIndex[_count], marketIndex.length);
    }

    function viewBuyerBoard(address _addr, uint256 _timestamp)
    external view returns (privateItems memory) {
        return buyerBoard[_addr][_timestamp];
    }
    function viewBuyerIndex(address _addr, uint256 _count) 
    external view returns (uint256, uint256) {
        return (Buyer[_addr].timeIndex[_count], Buyer[_addr].timeIndex.length);
    }
    function viewBuyer(address _addr)
    external view returns (users memory) {
        return Buyer[_addr];
    }

    function viewSellerBoard(address _addr, uint256 _timestamp)
    external view returns (publicItems memory) {
        return sellerBoard[_addr][_timestamp];
    }
    function viewSellerIndex(address _addr, uint256 _count) 
    external view returns (uint256, uint256) {
        return (Seller[_addr].user.timeIndex[_count], Seller[_addr].user.timeIndex.length);
    }
    function viewSelleritemIndex(address _addr, uint256 _count) 
    external view returns (itemIndex memory, uint256) {
        return (Seller[_addr].buyerIndex[_count], Seller[_addr].buyerIndex.length);
    }
    function viewSeller(address _addr)
    external view returns (seller memory) {
        return Seller[_addr];
    }

    function viewArbiterPublicIndex(address _addr, uint256 _count)
    external view returns (itemIndex memory, uint256) {
        return (Arbiter[_addr].publicIndex[_count], Arbiter[_addr].publicIndex.length);
    }
    function viewArbiterPrivateIndex(address _addr, uint256 _count)
    external view returns (itemIndex memory, uint256) {
        return (Arbiter[_addr].privateIndex[_count], Arbiter[_addr].privateIndex.length);
    }
    function viewArbiterMarketBoard(uint256 _count)
    external view returns (arbiter memory, uint256) {
        return (arbiterMarketBoard[_count], arbiterMarketBoard.length);
    }
    function viewArbiter(address _addr)
    external view returns (arbiter memory) {
        return Arbiter[_addr];
    }
    function viewStakingBalance(address _addr)
    external view returns (uint256) {
        return Arbiter[_addr].stakingBalance;
    }
}
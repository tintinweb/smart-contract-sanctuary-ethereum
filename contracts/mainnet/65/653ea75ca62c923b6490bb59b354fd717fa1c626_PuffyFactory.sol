/**
 *Submitted for verification at Etherscan.io on 2023-01-17
*/

//"SPDX-License-Identifier: MIT"
pragma solidity ^0.8.7;

contract PuffyFactory {
    string public constant name = "PUFFcoin";
    string public constant symbol = "PUFF";
    uint8 public constant decimals = 0;
    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event onMined(address, uint256 tokens);
    event levelUp(uint256 level);
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) allowed;
    mapping(address => uint256) public levelOf;
    uint256 public totalSupply;
    uint256 public contractLevel = 1;
    uint256 public numberInLevel;
    uint256 public puffBurned;
    uint256 public puffPrice = .01 ether;
    uint256 public ethBalance = address(this).balance;
    uint256 public burnPrice;

    constructor() payable {
        join();
    }

    function join() public payable {
        address customerAddress = msg.sender;
        require(levelOf[customerAddress] == 0 && msg.value == puffPrice);
        uint256 earnedTokens = 1;
        levelOf[customerAddress] = contractLevel;
        balanceOf[customerAddress] =
            balanceOf[customerAddress] +
            (earnedTokens);
        numberInLevel += 1;
        if (numberInLevel == contractLevel) {
            contractLevel += 1;
            numberInLevel = 0;
            mine();
            puffPrice += .01 ether;
        }
        totalSupply = totalSupply + earnedTokens;
        ethBalance = address(this).balance;
        burnPrice = ethBalance / totalSupply;
        emit onMined(customerAddress, earnedTokens);
    }

    function mine() public payable {
        address customerAddress = msg.sender;
        require(
            levelOf[customerAddress] != contractLevel &&
                levelOf[customerAddress] > 0 &&
                msg.value == puffPrice
        );
        uint256 earnedTokens = contractLevel - (levelOf[customerAddress]);
        numberInLevel = numberInLevel + (earnedTokens);
        if (numberInLevel == contractLevel) {
            contractLevel += 1;
            puffPrice += .01 ether;
            numberInLevel = 1;
            earnedTokens += 1;
            emit levelUp(contractLevel);
        } else if (numberInLevel > contractLevel) {
            numberInLevel = numberInLevel - (contractLevel);
            contractLevel += 1;
            puffPrice += .01 ether;
            emit levelUp(contractLevel);
        }
        levelOf[customerAddress] = contractLevel;
        totalSupply = totalSupply + earnedTokens;
        ethBalance = address(this).balance;
        burnPrice = ethBalance / totalSupply;
        balanceOf[customerAddress] =
            balanceOf[customerAddress] +
            (earnedTokens);
        emit onMined(customerAddress, earnedTokens);
    }

    function puffToMine(address tokenOwner) public view returns (uint256) {
        if (levelOf[tokenOwner] == 0) {
            return 1;
        } else {
            return contractLevel - levelOf[tokenOwner];
        }
    }

    function burnPuff(uint256 quantity) public {
        address payable customerAddress = payable(msg.sender);

        require(balanceOf[customerAddress] >= quantity);
        balanceOf[customerAddress] -= quantity;
        totalSupply -= quantity;
        puffBurned += quantity;
        uint256 payment = quantity * burnPrice;
        customerAddress.transfer(payment);
        ethBalance = address(this).balance;
        if (ethBalance > 0) {
            burnPrice = ethBalance / totalSupply;
        } else {
            burnPrice = 0;
        }
    }

    function burnAllPuff() public {
        burnPuff(levelOf[msg.sender]);
    }

    receive() external payable {
        ethBalance = address(this).balance;
        burnPrice = ethBalance / totalSupply;
    }

    function myPuffBalance() public view returns (uint256) {
        return balanceOf[msg.sender];
    }

    function myLevel() public view returns (uint256) {
        return levelOf[msg.sender];
    }

    function myBurnReturns() public view returns (uint256) {
        return burnPrice * myPuffBalance();
    }

    function transfer(address receiver, uint256 numTokens)
        public
        returns (bool)
    {
        require(numTokens <= balanceOf[msg.sender]);
        balanceOf[msg.sender] = balanceOf[msg.sender] - (numTokens);
        balanceOf[receiver] = balanceOf[receiver] + (numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens)
        public
        returns (bool)
    {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate)
        public
        view
        returns (uint256)
    {
        return allowed[owner][delegate];
    }

    function transferFrom(
        address owner,
        address buyer,
        uint256 numTokens
    ) public returns (bool) {
        require(numTokens <= balanceOf[owner]);
        require(numTokens <= allowed[owner][msg.sender]);
        balanceOf[owner] = balanceOf[owner] - (numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender] - (numTokens);
        balanceOf[buyer] = balanceOf[buyer] + (numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}
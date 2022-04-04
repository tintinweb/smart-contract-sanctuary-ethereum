/**
 *Submitted for verification at Etherscan.io on 2022-04-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);


    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

   
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

   
    function transfer(address to, uint256 amount) external returns (bool);


    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

 
    constructor() {
        _transferOwnership(_msgSender());
    }


    function owner() public view virtual returns (address) {
        return _owner;
    }

  
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }


    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

  
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }


    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20Metadata is IERC20 {
 
    function name() external view returns (string memory);

    
    function symbol() external view returns (string memory);

    
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }


    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

contract myToken is ERC20 {
    constructor() public ERC20("jagan's token", "jaganToken6") {
        _mint(address(this), 1000000000000000000000000);
    }
}


contract tokenFarm is Ownable {
    uint256 public entryToken = 10;
    uint256 public winTokens=10;
    uint256 public loseTokens=5;
    uint256  public whiteListedBonusTokens=5;
    uint256 randNonce = 0;
    uint256 private randomNumberGenerated;
    myToken public dappToken;
    string public gameDetails =
        "Guess the Random Number from (0-9) and win tokens. For every correct answer you will be rewarded 10 jaganToken, but for wrong answer 5 jaganToken will be deducted";
    address[] public users;
    uint256 public guessedNumberFromUser;
    mapping(address => uint256) public tokensUserHas;
    mapping(address => uint256) public tokensUserWon;
    mapping(address => uint256) public tokensUserLose;
    mapping(address => bool) public whiteListedAddressesCheck;
    address contractOwner;
    address[] public whiteListedAddresses;
    uint256 public randomNumberGeneratedFromGame;
    event generatedRandomNumber(uint256);
    event gameStatus(uint256,string);
    constructor(address _dappTokenAddress) public {
        dappToken = myToken(_dappTokenAddress);
        contractOwner=msg.sender;
        whiteListedAddresses.push(contractOwner);
    }

    function storeTokenAddress(address _tokenaddress) public onlyOwner{
        dappToken=myToken(_tokenaddress);
    }
    function getToken() public   {
        for (uint256 usersIndex = 0; usersIndex > users.length; usersIndex++) {
            require(users[usersIndex] != msg.sender, "Already registered");
        }
        users.push(msg.sender);
        tokensUserHas[msg.sender] = tokensUserHas[msg.sender] + entryToken;
    }

    function getGameDetails() public view returns (string memory) {
        return gameDetails;
    }

    function enterGame(uint256 _guessedNumberFromUser)
        public
        returns (uint256, string memory)
    {
        require(msg.sender!=contractOwner,"Owner can't enter the game");
        require(tokensUserHas[msg.sender]>0,"U need minimum 10 tokens to play the game");
        guessedNumberFromUser = _guessedNumberFromUser;
        randomNumberGenerated = getRandomNumber();
        randomNumberGeneratedFromGame=randomNumberGenerated;
         emit generatedRandomNumber(randomNumberGenerated);
        if (guessedNumberFromUser == randomNumberGenerated) {
            if(isWhiteListedAddress(msg.sender)==true){
                tokensUserHas[msg.sender]=tokensUserHas[msg.sender]+winTokens+whiteListedBonusTokens;
                tokensUserWon[msg.sender]=tokensUserWon[msg.sender]+winTokens+whiteListedBonusTokens;
            }
            tokensUserHas[msg.sender]=tokensUserHas[msg.sender]+winTokens;
            tokensUserWon[msg.sender]=tokensUserWon[msg.sender]+winTokens;
            emit gameStatus(randomNumberGenerated, "you won");
            return (randomNumberGenerated, "you won");
        } else {
            tokensUserHas[msg.sender]=tokensUserHas[msg.sender]-loseTokens;
            tokensUserLose[msg.sender]=tokensUserLose[msg.sender]+loseTokens;
            emit gameStatus(randomNumberGenerated, "oops! you lose");
            return (randomNumberGenerated, "oops! you lose");
        }
       
    }

    function getRandomNumber() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.timestamp, msg.sender, randNonce)
                )
            ) % 10;
    }


    function addTokensUsersWon() public onlyOwner {
        for (uint256 usersIndex = 0; usersIndex > users.length; usersIndex++) {
            dappToken.transfer(users[usersIndex],tokensUserWon[users[usersIndex]]);
        }
    }

      function decreaseTokensUsersLose() public onlyOwner {
        for (uint256 usersIndex = 0; usersIndex > users.length; usersIndex++) {
            dappToken.transferFrom(users[usersIndex],address(this),tokensUserLose[users[usersIndex]]);
        }
    }

    function addInitialTokensToUsers() public onlyOwner {
        for (uint256 usersIndex = 0; usersIndex > users.length; usersIndex++) {
            dappToken.transfer(users[usersIndex],tokensUserHas[users[usersIndex]]);
        }
    }

    function gameResults() public view returns(uint256,uint256,string memory) {
        if(guessedNumberFromUser==randomNumberGeneratedFromGame){
             return (guessedNumberFromUser,randomNumberGeneratedFromGame,"you won 10 tokens");
        }
        return (guessedNumberFromUser,randomNumberGeneratedFromGame,"sorry, you lose 5 tokens");
    }

    function addWhiteListedAddresses() public onlyOwner{
        for (uint256 usersIndex = 0; usersIndex > users.length; usersIndex++) {
            if(tokensUserWon[users[usersIndex]]>20){
                whiteListedAddresses.push(users[usersIndex]);
            }
        }
    }

    function isWhiteListedAddress(address _user) public view returns(bool){
        for(uint256 whiteListedAddressesIndex=0;whiteListedAddressesIndex>whiteListedAddresses.length;whiteListedAddressesIndex++){
            if(_user==whiteListedAddresses[whiteListedAddressesIndex]){
                return true;
            }
        }
        return false;
    }
}
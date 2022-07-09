/**
 *Submitted for verification at Etherscan.io on 2022-07-09
*/

// File: contracts/Context.sol



pragma solidity ^0.8.4;



abstract contract Context {

    function _msgSender() internal view virtual returns (address) {

        return msg.sender;

    }



    function _msgData() internal view virtual returns (bytes calldata) {

        return msg.data;

    }

}


// File: contracts/interfaces/IERC20.sol



pragma solidity ^0.8.4;



interface IERC20 {

    function totalSupply() external view returns (uint256);



    function balanceOf(address account) external view returns (uint256);



    function transfer(address recipient, uint256 amount)

        external

        returns (bool);



    function allowance(address owner, address spender)

        external

        view

        returns (uint256);



    function approve(address spender, uint256 amount) external returns (bool);



    function transferFrom(

        address sender,

        address recipient,

        uint256 amount

    ) external returns (bool);



    event Transfer(address indexed from, address indexed to, uint256 value);



    event Approval(

        address indexed owner,

        address indexed spender,

        uint256 value

    );

}


// File: contracts/interfaces/IERC20Metadata.sol



pragma solidity ^0.8.4;




interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);



    function symbol() external view returns (string memory);



    function decimals() external view returns (uint8);

}


// File: contracts/ERC20.sol



pragma solidity ^0.8.4;






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



    function transfer(address recipient, uint256 amount)

        public

        virtual

        override

        returns (bool)

    {

        _transfer(_msgSender(), recipient, amount);

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

        _approve(_msgSender(), spender, amount);

        return true;

    }



    function transferFrom(

        address sender,

        address recipient,

        uint256 amount

    ) public virtual override returns (bool) {

        _transfer(sender, recipient, amount);



        uint256 currentAllowance = _allowances[sender][_msgSender()];

        require(

            currentAllowance >= amount,

            "ERC20: transfer amount exceeds allowance"

        );

        unchecked {

            _approve(sender, _msgSender(), currentAllowance - amount);

        }



        return true;

    }



    function increaseAllowance(address spender, uint256 addedValue)

        public

        virtual

        returns (bool)

    {

        _approve(

            _msgSender(),

            spender,

            _allowances[_msgSender()][spender] + addedValue

        );

        return true;

    }



    function decreaseAllowance(address spender, uint256 subtractedValue)

        public

        virtual

        returns (bool)

    {

        uint256 currentAllowance = _allowances[_msgSender()][spender];

        require(

            currentAllowance >= subtractedValue,

            "ERC20: decreased allowance below zero"

        );

        unchecked {

            _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        }



        return true;

    }



    function _transfer(

        address sender,

        address recipient,

        uint256 amount

    ) internal virtual {

        require(sender != address(0), "ERC20: transfer from the zero address");

        require(recipient != address(0), "ERC20: transfer to the zero address");



        _beforeTokenTransfer(sender, recipient, amount);



        uint256 senderBalance = _balances[sender];

        require(

            senderBalance >= amount,

            "ERC20: transfer amount exceeds balance"

        );

        unchecked {

            _balances[sender] = senderBalance - amount;

        }

        _balances[recipient] += amount;



        emit Transfer(sender, recipient, amount);



        _afterTokenTransfer(sender, recipient, amount);

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


// File: contracts/Faucet.sol



pragma solidity >= 0.7.0 <= 0.8.4;




contract Faucet {

    uint256 public usdtAmount = 100000000000000000000;

    uint256 public vndtAmount = 2335500000000000000000000;

    uint256 ethAmount = 0.001 ether;

    uint256 public waitTime = 10 minutes;



    ERC20 public usdtToken;

    ERC20 public vndtToken;



    //state variable to keep track of owner

    address public owner;

    mapping(address => uint) public timeouts;



    event Withdrawal(address indexed to);

    event Deposit(address indexed from, uint amount);



    constructor(address _usdtToken, address _vndtToken) {

        require(_usdtToken != address(0));

        require(_vndtToken != address(0));

        //Will be called on creation of the smart contract.

        usdtToken = ERC20(_usdtToken);

        vndtToken = ERC20(_vndtToken);

        owner = msg.sender;

    }



    //function modifier

    modifier onlyOwner {

        require(msg.sender == owner, "Only owner can call this function.");

        _;

    }



    //function to change the owner.  Only the owner of the contract can call this function

    function setOwner(address newOwner) public onlyOwner {

        owner = newOwner;

    }



    function setWaitTime(uint newWaitTime) public onlyOwner {

        waitTime = newWaitTime;

    }



    //function to set the amount allowable to be claimed. Only the owner can call this function

    function setUsdtAmountAllowed(uint newAmountAllowed) public onlyOwner {

        usdtAmount = newAmountAllowed;

    }



    //function to set the amount allowable to be claimed. Only the owner can call this function

    function setVndtAmountAllowed(uint newAmountAllowed) public onlyOwner {

        vndtAmount = newAmountAllowed;

    }



    //  Sends 0.001 ETH to the sender when the faucet has enough funds

    function withdraw() external {



        require(address(this).balance >= ethAmount, "This faucet is empty. Please check back later.");

        require(timeouts[msg.sender] < block.timestamp - waitTime, "Lock time has not expired. Please check back later.");



        payable(msg.sender).transfer(ethAmount);

        usdtToken.transfer(msg.sender, usdtAmount);

        vndtToken.transfer(msg.sender, vndtAmount);

        timeouts[msg.sender] = block.timestamp;



        emit Withdrawal(msg.sender);

    }



    function faucet(address to) public {



        require(address(this).balance >= ethAmount, "This faucet is empty. Please check back later.");

        require(timeouts[msg.sender] < block.timestamp - waitTime, "Lock time has not expired. Please check back later.");



        payable(to).transfer(ethAmount);

        usdtToken.transfer(to, usdtAmount);

        vndtToken.transfer(to, vndtAmount);

        timeouts[msg.sender] = block.timestamp;



        emit Withdrawal(to);

    }



    //  Sending Tokens to this faucet fills it up

    receive() external payable {

        emit Deposit(msg.sender, msg.value);

    }





    //  Destroys this smart contract and sends all remaining funds to the owner

    function destroy() public {

        require(msg.sender == owner, "Only the owner of this faucet can destroy it.");

        selfdestruct(payable(msg.sender));

    }

}
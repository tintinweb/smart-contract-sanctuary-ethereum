/**
 *Submitted for verification at Etherscan.io on 2022-10-24
*/

/**
 *Submitted for verification at BscScan.com on 2022-10-22
*/

/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.0;

abstract contract Context {
    function _msgSender() public view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() public view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }


    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

   
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract TIA is Context, IERC20, Ownable {

    struct Fees {
        uint256 reflectFee;
        uint256 rebalanceFee;
        uint256 burnFee;
    }

    address private TiamondsAddress;



    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    address private constant deadWallet = 0x000000000000000000000000000000000000dEaD;

    uint256 public constant MAX = ~uint256(0);
    uint256 public constant _tTotal = 100000 ether ;
    uint256 public _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private constant _name = "Tia Token";
    string private constant _symbol = "TIA";
    uint8 private constant _decimals = 18;

    uint256 private _reflectionFee = 200;

    event SetTiamondsAddress(address);
    event ApproveTiamondsAddress(address, address, uint256);


    constructor() {
    
        _rOwned[owner()] = _rTotal;
        emit Transfer(address(0), owner(), _tTotal);
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() external pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {   
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }


    function approveTiamondSC() external onlyOwner returns (bool) {
        _approve(msg.sender, TiamondsAddress, _tTotal);
        emit ApproveTiamondsAddress(msg.sender, TiamondsAddress, _tTotal);
        return true;
    }

    function transferFrom( address sender, address recipient, uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve( sender, _msgSender(), _allowances[sender][_msgSender()]-amount
        );
        return true;
    }




    function totalFees() external view returns (uint256) {
        return _tFeeTotal;
    }

    function reflect(uint256 tAmount) external {
        address sender = _msgSender();

        (uint256 rAmount, , , , ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender]-rAmount;
        _rTotal = _rTotal-rAmount;
        _tFeeTotal = _tFeeTotal + tAmount;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        external view returns (uint256)
    {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , ) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount /currentRate;
    }



    function _approve( address owner, address spender, uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer( address sender, address recipient, uint256 amount
    ) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
 

            _transferStandard(sender, recipient, amount);
        
    }

    function _transferStandard( address sender,  address recipient, uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            Fees memory rFees,
            uint256 tTransferAmount,
            Fees memory tFees
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _reflectFee(rFees.reflectFee, tFees.reflectFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }




    function _reflectFee(uint256 rReflectFee, uint256 tReflectFee) private {
        _rTotal = _rTotal - rReflectFee;
        _tFeeTotal = _tFeeTotal + tReflectFee;
    }


    function _getValues(uint256 tAmount) private view returns (uint256,uint256, Fees memory,uint256,Fees memory ) {
        (uint256 tTransferAmount, Fees memory tFees) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            Fees memory rFees) = _getRValues(tAmount, tFees, currentRate);
        return (rAmount, rTransferAmount, rFees, tTransferAmount, tFees);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, Fees memory)
    {
        Fees memory tFees;
        tFees.reflectFee = (tAmount * _reflectionFee)/(1000);
        uint256 tTransferAmount = tAmount - tFees.reflectFee;
        return (tTransferAmount, tFees);
    }

    function _getRValues( uint256 tAmount, Fees memory tFees, uint256 currentRate )  private  pure  returns ( uint256, uint256, Fees memory)
    {
        Fees memory rFees;
        uint256 rAmount = tAmount * currentRate;
        rFees.reflectFee = tFees.reflectFee * currentRate;
        uint256 rTransferAmount = rAmount-rFees.reflectFee;
        return (rAmount, rTransferAmount, rFees);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply/tSupply;
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
     
        if (rSupply < _rTotal/_tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function reflectionFee() external view returns (uint256) {
        return _reflectionFee;
    }
 

    function _burn(uint256 burnAmount) internal {
        _transfer(address(this), deadWallet, burnAmount);
        emit Transfer(address(this), deadWallet, burnAmount);
    }
}
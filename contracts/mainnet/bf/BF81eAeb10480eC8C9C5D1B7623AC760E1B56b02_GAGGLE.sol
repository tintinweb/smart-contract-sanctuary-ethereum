/*








 ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄            ▄▄▄▄▄▄▄▄▄▄▄ 
▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░▌          ▐░░░░░░░░░░░▌
▐░█▀▀▀▀▀▀▀▀▀ ▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀▀▀ ▐░█▀▀▀▀▀▀▀▀▀ ▐░▌          ▐░█▀▀▀▀▀▀▀▀▀ 
▐░▌          ▐░▌       ▐░▌▐░▌          ▐░▌          ▐░▌          ▐░▌          
▐░▌ ▄▄▄▄▄▄▄▄ ▐░█▄▄▄▄▄▄▄█░▌▐░▌ ▄▄▄▄▄▄▄▄ ▐░▌ ▄▄▄▄▄▄▄▄ ▐░▌          ▐░█▄▄▄▄▄▄▄▄▄ 
▐░▌▐░░░░░░░░▌▐░░░░░░░░░░░▌▐░▌▐░░░░░░░░▌▐░▌▐░░░░░░░░▌▐░▌          ▐░░░░░░░░░░░▌
▐░▌ ▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌▐░▌ ▀▀▀▀▀▀█░▌▐░▌ ▀▀▀▀▀▀█░▌▐░▌          ▐░█▀▀▀▀▀▀▀▀▀ 
▐░▌       ▐░▌▐░▌       ▐░▌▐░▌       ▐░▌▐░▌       ▐░▌▐░▌          ▐░▌          
▐░█▄▄▄▄▄▄▄█░▌▐░▌       ▐░▌▐░█▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄▄▄ ▐░█▄▄▄▄▄▄▄▄▄ 
▐░░░░░░░░░░░▌▐░▌       ▐░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌











*/














// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IERC20.sol";

contract GAGGLE is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    address public tokenPairAddress;
    address public teamAddress = 0x02D7E6bC55Bcf210bc7f79F4e15F7E439FF2425d;
    address public treasuryAddress = 0x1534854fE07d619ce3A2c4c5c03eb35A49A9E652;
    address public psWallet = 0x5Fcb81060feeA737902033F0411AcFd0aCE1448C;
    address public cmoAddress = 0xed564EF21C2A46FcA92fB9fF29cb5b53a10C90B0;
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;

    mapping(address => uint256) private _reserveTokenBalance;
    mapping(address => uint256) private _circulatingTokenBalance;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcluded;
    address[] private _excluded;

    // The highest possible number.
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _totalSupply = 20000000000 * 10**9;
    uint256 private _totalReserve = (MAX - (MAX % _totalSupply));
    uint256 private _transactionFeeTotal;

    bool private initialSellTaxActive = false;
    bool private initialSellTaxSet = false;

    uint8 private _decimals = 9;
    string private _symbol = "$GAG";
    string private _name = "Gaggle";


       struct ReserveValues {
        uint256 reserveAmount;
        uint256 reserveTransferAmountMarketing;
        uint256 reserveTransferAmount;
        uint256 reserveTransferAmountTeam;
        uint256 reserveTransferAmountBurnEm;
    }

        struct TransactionValues {
        uint256 transactionFee;
        uint256 transferAmount;
        uint256 netTransferAmount;
        uint256 marketingFee;
        uint256 teamTax;
        uint256 burnEm;
    }


            ////////////////////////////////////
            //  ____  ____   ____  ______ 
            // |    ||    \ |    ||      |
            //  |  | |  _  | |  | |      |
            //  |  | |  |  | |  | |_|  |_|
            //  |  | |  |  | |  |   |  |  
            //  |  | |  |  | |  |   |  |  
            // |____||__|__||____|  |__|  
            //
            ////////////////////////////////////

    constructor() {
        uint256 blackHole = _totalSupply.div(2);
        uint256 presale = blackHole.mul(23).div(100);
        uint256 lp = blackHole.mul(30).div(100);
        uint256 treasury = blackHole.mul(28).div(100);
        uint256 team = blackHole.mul(18).div(100);
        uint256 cmo = blackHole.mul(10).div(1000);

         uint256 rate = getRate();

        _reserveTokenBalance[burnAddress] = blackHole.mul(rate);
        _reserveTokenBalance[_msgSender()] = presale.mul(rate) + lp.mul(rate);
        _reserveTokenBalance[treasuryAddress] = treasury.mul(rate);
        _reserveTokenBalance[teamAddress] = team.mul(rate);
        _reserveTokenBalance[cmoAddress] = cmo.mul(rate);

        emit Transfer(address(0), burnAddress, blackHole);
        emit Transfer(address(0), _msgSender(), presale);
        emit Transfer(address(0), _msgSender(), lp);
        emit Transfer(address(0), treasuryAddress, treasury);
        emit Transfer(address(0), teamAddress, team);
        emit Transfer(address(0), cmoAddress, cmo);
    }

    ///////////////////////////////////////
    //           _   _                
    //          | | | |               
    //  ___  ___| |_| |_ ___ _ __ ___ 
    // / __|/ _ \ __| __/ _ \ '__/ __|
    // \__ \  __/ |_| ||  __/ |  \__ \
    // |___/\___|\__|\__\___|_|  |___/
    //
    //
    ///////////////////////////////////////

                               

    function deathTaxOn() public onlyOwner {
        initialSellTaxActive = true;
    }
    function deathTaxOff() public onlyOwner {
        initialSellTaxActive = false;
    }
    function setTeamAddress(address _teamAddress) public onlyOwner {
        teamAddress = _teamAddress;
    }
    function setTreasuryAddress(address _treasuryAddress) public onlyOwner {
        treasuryAddress = _treasuryAddress;
    }
    function setpsWallet(address _psWallet) public onlyOwner {
        psWallet = _psWallet;
    }
    function setCmoAddress(address _cmoAddress) public onlyOwner {
        cmoAddress = _cmoAddress;
    }
    function setTokenPairAddress(address _tokenPairAddress) public onlyOwner {
        tokenPairAddress = _tokenPairAddress;
    }
 
    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
 
    function totalSupply() public pure override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _circulatingTokenBalance[account];
        return tokenBalanceFromReserveAmount(_reserveTokenBalance[account]);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
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
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
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
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

 
    function getOwner() external view override returns (address) {
        return owner();
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _transactionFeeTotal;
    }

    function distributeToAllHolders(uint256 transferAmount) public {
        address sender = _msgSender();
        require(
            !_isExcluded[sender],
            "Excluded addresses cannot call this function"
        );
        (, ReserveValues memory reserveValues, ) = _getValues(transferAmount);
        _reserveTokenBalance[sender] = _reserveTokenBalance[sender].sub(
            reserveValues.reserveAmount
        );
        _totalReserve = _totalReserve.sub(reserveValues.reserveAmount);
        _transactionFeeTotal = _transactionFeeTotal.add(transferAmount);
    }

    function reserveBalanceFromTokenAmount(
        uint256 transferAmount,
        bool deductTransferReserveFee
    ) public view returns (uint256) {
        (, ReserveValues memory reserveValues, ) = _getValues(transferAmount);
        require(
            transferAmount <= _totalSupply,
            "Amount must be less than supply"
        );
        if (!deductTransferReserveFee) {
            return reserveValues.reserveAmount;
        } else {
            return reserveValues.reserveTransferAmount;
        }
    }

    function tokenBalanceFromReserveAmount(uint256 reserveAmount)
        public
        view
        returns (uint256)
    {
        require(
            reserveAmount <= _totalReserve,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = getRate();
        return reserveAmount.div(currentRate);
    }

    function excludeAccount(address account) external onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        if (_reserveTokenBalance[account] > 0) {
            _circulatingTokenBalance[account] = tokenBalanceFromReserveAmount(
                _reserveTokenBalance[account]
            );
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccount(address account) external onlyOwner {
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _circulatingTokenBalance[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function applyExternalTransactionTax(
        ReserveValues memory reserveValues,
        TransactionValues memory transactionValues,
        address sender
    ) private {
        _reserveTokenBalance[teamAddress] = _reserveTokenBalance[teamAddress]
            .add(reserveValues.reserveTransferAmountTeam);
        _reserveTokenBalance[treasuryAddress] = _reserveTokenBalance[
            treasuryAddress
        ].add(reserveValues.reserveTransferAmountMarketing);
        _reserveTokenBalance[burnAddress] = _reserveTokenBalance[burnAddress]
            .add(reserveValues.reserveTransferAmountBurnEm);

        emit Transfer(sender, teamAddress, transactionValues.teamTax);
        emit Transfer(sender, treasuryAddress, transactionValues.teamTax);
        emit Transfer(sender, burnAddress, transactionValues.burnEm);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }

    /////////////////////////////////////////////////////  :) --->
    //   _____      ____ _ _ __  _ __   ___ _ __ ___ 
    //  / __\ \ /\ / / _` | '_ \| '_ \ / _ \ '__/ __|
    //  \__ \\ V  V / (_| | |_) | |_) |  __/ |  \__ \
    //  |___/ \_/\_/ \__,_| .__/| .__/ \___|_|  |___/
    //                    | |   | |                  
    //                    |_|   |_|                  
    //////////////////////////////////////////////////////   :-O  <----- 

    function _transferStandard(
        address sender,
        address recipient,
        uint256 transferAmount
    ) private {
        (
            TransactionValues memory transactionValues,
            ReserveValues memory reserveValues,

        ) = _getValues(transferAmount);
        _reserveTokenBalance[sender] = _reserveTokenBalance[sender].sub(
            reserveValues.reserveAmount
        );
        _reserveTokenBalance[recipient] = _reserveTokenBalance[recipient].add(
            reserveValues.reserveTransferAmount
        );
        emit Transfer(sender, recipient, transactionValues.netTransferAmount);
        applyExternalTransactionTax(reserveValues, transactionValues, sender);
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 transferAmount
    ) private {
        (
            TransactionValues memory transactionValues,
            ReserveValues memory reserveValues,

        ) = _getValues(transferAmount);

        _reserveTokenBalance[sender] = _reserveTokenBalance[sender].sub(
            reserveValues.reserveAmount
        );

        if (recipient == tokenPairAddress) {
            _reserveTokenBalance[recipient] = _reserveTokenBalance[recipient]
                .add(reserveValues.reserveAmount);
            _circulatingTokenBalance[recipient] = _circulatingTokenBalance[
                recipient
            ].add(transferAmount);

            emit Transfer(sender, recipient, transferAmount);
        } else {
            _reserveTokenBalance[recipient] = _reserveTokenBalance[recipient]
                .add(reserveValues.reserveTransferAmount);
            _circulatingTokenBalance[recipient] = _circulatingTokenBalance[
                recipient
            ].add(transactionValues.netTransferAmount);
            emit Transfer(
                sender,
                recipient,
                transactionValues.netTransferAmount
            );
            applyExternalTransactionTax(
                reserveValues,
                transactionValues,
                sender
            );
        }
    }

/////////////////////////////////////////////////////////////////////////////////////////
    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 transferAmount
    ) private {
        (
            TransactionValues memory transactionValues,
            ReserveValues memory reserveValues,

        ) = _getValues(transferAmount);
        _circulatingTokenBalance[sender] = _circulatingTokenBalance[sender].sub(
            transferAmount
        );
        _reserveTokenBalance[sender] = _reserveTokenBalance[sender].sub(
            reserveValues.reserveAmount
        );

   
        if (!initialSellTaxActive) {
            _reserveTokenBalance[recipient] = _reserveTokenBalance[recipient]
                .add(reserveValues.reserveTransferAmount);
            emit Transfer(
                sender,
                recipient,
                transactionValues.netTransferAmount
            );
            applyExternalTransactionTax(
                reserveValues,
                transactionValues,
                sender
            );
           
        } else {

            /////////////////////////////////////
            //  | |__  ___| |_   / _|_  _| |__
            //  | '_ \/ _ \  _| |  _| || | / /
            //  |_.__/\___/\__| |_|  \_,_|_\_\
            ////////////////////////////////////                     

            // this is where we pump one in the bots!!  ///
            _reserveTokenBalance[recipient] = _reserveTokenBalance[recipient]
                .add(reserveValues.reserveAmount.div(10));
            emit Transfer(sender, recipient, transferAmount.div(10));
        }
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 transferAmount
    ) private {
        (
            TransactionValues memory transactionValues,
            ReserveValues memory reserveValues,

        ) = _getValues(transferAmount);
        _circulatingTokenBalance[sender] = _circulatingTokenBalance[sender].sub(
            transferAmount
        );
        _reserveTokenBalance[sender] = _reserveTokenBalance[sender].sub(
            reserveValues.reserveAmount
        );
        _reserveTokenBalance[recipient] = _reserveTokenBalance[recipient].add(
            reserveValues.reserveTransferAmount
        );
        _circulatingTokenBalance[recipient] = _circulatingTokenBalance[
            recipient
        ].add(transactionValues.netTransferAmount);

        emit Transfer(sender, recipient, transactionValues.netTransferAmount);
        applyExternalTransactionTax(reserveValues, transactionValues, sender);
 
    }
    
    function _getValues(uint256 transferAmount)
        private
        view
        returns (
            TransactionValues memory,
            ReserveValues memory,
            uint256
        )
    {
        TransactionValues memory transactionValues = _getTValues(
            transferAmount
        );
        uint256 currentRate = getRate();
        ReserveValues memory reserveValues = _getRValues(
            transferAmount,
            transactionValues,
            currentRate
        );

        return (transactionValues, reserveValues, currentRate);
    }

    function _getTValues(uint256 transferAmount)
        private
        pure
        returns (TransactionValues memory)
    {
        TransactionValues memory transactionValues;

        transactionValues.transactionFee = transferAmount.mul(2).div(100);

        transactionValues.teamTax = transferAmount.mul(2).div(100);

        transactionValues.burnEm = transferAmount.mul(10).div(1000);

        transactionValues.netTransferAmount = transferAmount
            .sub(transactionValues.transactionFee)
            .sub(transactionValues.teamTax)
            .sub(transactionValues.burnEm);

        return transactionValues;
    }

    function _getRValues(
        uint256 transferAmount,
        TransactionValues memory transactionValues,
        uint256 currentRate
    ) private pure returns (ReserveValues memory) {
        ReserveValues memory reserveValues;
        reserveValues.reserveAmount = transferAmount.mul(currentRate);
        reserveValues.reserveTransferAmountMarketing = transactionValues
            .transactionFee
            .mul(currentRate);
        reserveValues.reserveTransferAmountTeam = transactionValues.teamTax.mul(
            currentRate
        );
        reserveValues.reserveTransferAmountBurnEm = transactionValues
            .burnEm
            .mul(currentRate);

        reserveValues.reserveTransferAmount = reserveValues
            .reserveAmount
            .sub(reserveValues.reserveTransferAmountMarketing)
            .sub(reserveValues.reserveTransferAmountTeam)
            .sub(reserveValues.reserveTransferAmountBurnEm);

        return reserveValues;
    }

    function getRate() public view returns (uint256) {
        (uint256 reserveSupply, uint256 totalTokenSupply) = getCurrentSupply();
        return reserveSupply.div(totalTokenSupply);
    }

    function getCurrentSupply() public view returns (uint256, uint256) {
        uint256 reserveSupply = _totalReserve;
        uint256 totalTokenSupply = _totalSupply;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _reserveTokenBalance[_excluded[i]] > reserveSupply ||
                _circulatingTokenBalance[_excluded[i]] > totalTokenSupply
            ) return (_totalReserve, _totalSupply);
            reserveSupply = reserveSupply.sub(
                _reserveTokenBalance[_excluded[i]]
            );
            totalTokenSupply = totalTokenSupply.sub(
                _circulatingTokenBalance[_excluded[i]]
            );
        }
        if (reserveSupply < _totalReserve.div(_totalSupply))
            return (_totalReserve, _totalSupply);
        return (reserveSupply, totalTokenSupply);
    }
}





                     
// ___  __ ____ ___  ___
// \  \/ // __ \\  \/  /
//  \   /\  ___/ >    < 
//   \_/  \___  >__/\_ \
//            \/      \/
//
/// vexcooler.eth /// anonX

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
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

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT




pragma solidity ^0.8.0;

interface IERC20 {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
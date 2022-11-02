/**
 *Submitted for verification at Etherscan.io on 2022-11-02
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    
    function symbol() external view returns(string memory);
    
    function name() external view returns(string memory);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
    
    /**
     * @dev Returns the number of decimal places
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Ownable {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier onlyOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}

interface IThirdParty {
    function isAllowed(address user) external view returns (bool);
}

contract USDH is IERC20, Ownable {

    // Third Party Approval Integration
    IThirdParty public thirdParty;

    // total supply
    uint256 private _totalSupply;

    // token data
    string private constant _name = "Husl USD";
    string private constant _symbol = "USDH";
    uint8  private constant _decimals = 18;

    // balances
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    // Redeem Logs
    struct RedeemLog {
        address user;
        uint256 amount;
        uint256 timestamp;
        uint256 uuid;
        bool fulfilled;
    }

    // Log ID => Logs
    mapping ( uint256 => RedeemLog ) public logs;

    // Redeem Log Nonce
    uint256 public currentLogID;

    /**
        Ensures `account` is KYC Verified Before Permitting
        Access To Certain Functionality
     */
    modifier isVerified(address account) {
        require(
            thirdParty.isAllowed(account),
            'Account Not Allowed'
        );
        _;
    }

    // Events
    event Redeem(uint256 uuid, uint256 redeemLogId, address sender, uint256 amount, uint256 timestamp);
    event NewThirdPartyVerification(address oldVerification, address newVerification);

    // emit event for etherscan tracking
    constructor(address thirdParty_) {
        thirdParty = IThirdParty(thirdParty_);
        emit Transfer(address(0), msg.sender, 0);
    }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    
    function name() public pure override returns (string memory) {
        return _name;
    }

    function symbol() public pure override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /** Transfer Function */
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    /** Transfer Function */
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(
            _allowances[sender][msg.sender] >= amount,
            'Insufficient Allowance'
        );
        _allowances[sender][msg.sender] -= amount;
        return _transferFrom(sender, recipient, amount);
    }

    // Public Functions

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) external {
        require(
            _allowances[account][msg.sender] >= amount,
            'Insufficient Allowance'
        );
        _allowances[account][msg.sender] -= amount;
        _burn(account, amount);
    }

    function redeem(uint256 uuid, uint256 amount) external {
        _redeem(msg.sender, amount, uuid);
    }


    // Owner Functions

    function setThirdPartyVerification(address newThirdParty) external onlyOwner {
        require(
            IThirdParty(newThirdParty).isAllowed(this.getOwner()) == true,
            'Owner Not Allowed'
        );
        require(
            address(thirdParty) != newThirdParty,
            'Parties Can Not Match'
        );

        // emit event
        emit NewThirdPartyVerification(address(thirdParty), newThirdParty);

        // set new party
        thirdParty = IThirdParty(newThirdParty);
    }

    function ownerBurn(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);
    }

    function ownerRedeem(uint256 uuid, address account, uint256 amount) external onlyOwner {
        _redeem(account, amount, uuid);
    }

    function fulfill(uint256 logId) external onlyOwner {
        logs[logId].fulfilled = true;
    }

    function batchFulfill(uint256[] calldata logIds) external onlyOwner {
        uint len = logIds.length;
        for (uint i = 0; i < len;) {
            logs[logIds[i]].fulfilled = true;
            unchecked { ++i; }
        }
    }

    function removeFulfill(uint256[] calldata logIds) external onlyOwner {
        uint len = logIds.length;
        for (uint i = 0; i < len;) {
            logs[logIds[i]].fulfilled = false;
            unchecked { ++i; }
        }
    }

    function credit(address to, uint256 amount) external onlyOwner {
        _credit(to, amount);
    }

    function batchCredit(address[] calldata tos, uint256[] calldata amounts) external onlyOwner {
        uint len = tos.length;
        require(len == amounts.length, 'Invalid Lengths');
        for (uint i = 0; i < len;) {
            _credit(tos[i], amounts[i]);
            unchecked { ++i; }
        }
    }

    // Internal Transactions

    function _credit(address to, uint256 amount) internal isVerified(to) {

        // credit `amount` of tokens to `to`
        _balances[to] += amount;
        _totalSupply += amount;        

        // emit transfer event
        emit Transfer(address(0), to, amount);
    }
    
    /** Internal Transfer */
    function _transferFrom(address sender, address recipient, uint256 amount) internal isVerified(recipient) returns (bool) {
        require(
            amount <= _balances[sender],
            'Insufficient Balance'
        );
        require(
            amount > 0,
            'Zero Transfer Amount'
        );

        // Reallocate Balances
        unchecked {
            _balances[sender] -= amount;
            _balances[recipient] += amount;
        }

        // emit transfer
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _burn(address account, uint256 amount) internal {
        require(
            _balances[account] >= amount,
            'Insufficient Balance'
        );

        // already checked balance, so decrement without underflow validation
        unchecked {
            _balances[account] -= amount;
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);
    }

    function _redeem(address account, uint256 amount, uint256 uuid) internal {

        // Burn `Amount` From `Account`
        _burn(account, amount);

        // Add To Redeem Logs
        logs[currentLogID] = RedeemLog({
            user: account,
            amount: amount,
            timestamp: block.timestamp,
            uuid: uuid,
            fulfilled: false
        });

        // emit Redemption Event
        emit Redeem(uuid, currentLogID, account, amount, block.timestamp);

        // increment nonce
        unchecked {
            currentLogID++;
        }
    }


    // Read Functions

    function owner() external view returns (address) {
        return this.getOwner();
    }

    function fetchLogs(uint256 startIndex, uint256 endIndex) external view returns(
        address[] memory users,
        uint256[] memory amounts,
        uint256[] memory timestamps,
        uint256[] memory uuids,
        bool[] memory fulfilled
    ) {

        uint len = endIndex - startIndex;
        users = new address[](len);
        amounts = new uint256[](len);
        timestamps = new uint256[](len);
        uuids = new uint256[](len);
        fulfilled = new bool[](len);

        uint count = 0;
        for (uint i = startIndex; i < endIndex;) {

            users[count] = logs[i].user;
            amounts[count] = logs[i].amount;
            timestamps[count] = logs[i].timestamp;
            uuids[count] = logs[i].uuid;
            fulfilled[count] = logs[i].fulfilled;

            unchecked {i++; count++;}
        }
    }
}
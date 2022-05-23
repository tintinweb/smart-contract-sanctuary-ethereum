/**
 *Submitted for verification at Etherscan.io on 2022-05-23
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;


interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

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




contract Timelock is Ownable {

    struct depositInfo {
        address depositor;
        address beneficiary;
        uint256 depositAmount;
        uint256 depositRemaining;
        uint releaseTime;
    }

    struct uniqueDepositInfo {
        address beneficiary;
        address token;
    }

    bool internal lock;
    string private _name = "Timelock";

    address payable private _owner;
    address private edithContractAddress;

    uint256 private edithRequired = 50;
    uint256 private totalEdithCollected = 0;
    //uint256 private ownerEmergencyUnlockTime = 0;
    mapping (address => mapping (address => depositInfo[])) private deposited;
    uniqueDepositInfo[] UDI;

    mapping (address => uint256) private tokenDepoistBalances;
    mapping (address => uint256) private creditsAvailable;


    constructor(address payable ownerIn) {
        //end = block.timestamp + duration;
        _owner = ownerIn;
    }

    modifier nonReentrant() {
        require(!lock, "no reentrancy allowed");
        lock = true;
        _;
        lock = false;
    }

    receive() external payable {}

    function name() public view returns(string memory){
        return _name;
    }

    function getOwner() public view returns(address) {
        return _owner;
    }

    function setOwner(address payable newOwner) external onlyOwner returns(bool) {
        _owner = newOwner;
        return true;
    }

    function setEdithContractAddress(address newAddress) public onlyOwner {
        edithContractAddress = newAddress;
    }

    function getEdithContractAddress() public view returns(address) {
        return edithContractAddress;
    }

    function setEdithRequired(uint256 amount) public onlyOwner returns(bool) {
        edithRequired = amount;
        return true;
    }

    function getEdithRequired() public view returns(uint256) {
        return edithRequired;
    }

    //transfers all edith credits to the contract owner
    function loadCredits(uint256 amount) public nonReentrant returns(bool) {
        bool success;
        if (msg.sender != _owner){
            success = IERC20(edithContractAddress).transferFrom(msg.sender, _owner, amount);
            if (success){
                creditsAvailable[msg.sender] += amount;
                totalEdithCollected += amount;
            }
        } 
        return true;
    }

    function getLoadedCredits(address account) public view returns(uint256) {
        return creditsAvailable[account];
    }

    function getTotalEdithCollected() public view returns(uint256) {
        return totalEdithCollected;
    }

    function deposit(address beneficiary, address token, uint256 amount, uint256 delayTime) public nonReentrant returns(bool){
        //demand credits unless edithContract address is set to zero or if caller is owner or if edithRrquired == 0
        if (edithContractAddress != address(0) && msg.sender != _owner && edithRequired > 0){
            require(creditsAvailable[msg.sender] >= edithRequired, "you need more edith credits deposited");
            creditsAvailable[msg.sender] -= edithRequired;
        }
        if (deposited[beneficiary][token].length ==  0){
            UDI.push(uniqueDepositInfo(beneficiary, token));
        }
        uint256 releaseTime = block.timestamp + delayTime;
        deposited[beneficiary][token].push(depositInfo(msg.sender, beneficiary, amount, amount, releaseTime));
        bool success = IERC20(token).transferFrom(msg.sender, address(this), amount);

        return true;
    }

    function numUniqueDeposits() public view returns(uint256){
        return UDI.length;
    }

    function viewUniqueDeposit(uint256 index) public view returns(address, address){
        require(index < UDI.length);
        uniqueDepositInfo memory UD = UDI[index];
        return (UD.beneficiary, UD.token);
    }

    function numberOfDeposits(address beneficiary, address token) public view returns(uint256) {
        return deposited[beneficiary][token].length;
    }

    function viewDeposit(address beneficiary, address token, uint depositNumber) public view returns(address, address, uint256, uint256, uint256) {
        require(deposited[beneficiary][token].length >= depositNumber, "invalid deposit number");
        depositInfo memory DI = deposited[beneficiary][token][depositNumber];
        return (DI.depositor, DI.beneficiary, DI.depositAmount, DI.depositRemaining, DI.releaseTime);
    }

    function withdraw(address token, uint256 amount) public nonReentrant returns(bool) {
        require(amount > 0, "amount cannot be 0");
        address beneficiary = msg.sender;
        depositInfo[] memory DIL = deposited[beneficiary][token];
        require(DIL.length > 0, "no tokens deposited.");
        
        depositInfo memory DI;
        uint currentTime = block.timestamp;

        uint256 numTokensDeducted = 0;
        uint256 numTokensStillNeeded = amount;
        //uint[] memory depositsEmptied;
        for (uint256 i=0; i<DIL.length; i++) {
            if (numTokensStillNeeded > 0){
                DI = DIL[i];
                if (DI.releaseTime <= currentTime && DI.depositRemaining > 0) {
                    if (DI.depositRemaining <= numTokensStillNeeded){
                        numTokensStillNeeded -= DI.depositRemaining;
                        deposited[beneficiary][token][i].depositRemaining = 0;
                    } else { //number in this deposit are greater than num needed.
                        deposited[beneficiary][token][i].depositRemaining -= numTokensStillNeeded;
                        numTokensStillNeeded = 0;
                    }
                }
            }
        }
        numTokensDeducted = amount - numTokensStillNeeded;
        require(numTokensDeducted > 0, "no tokens were ready to unlock");
        bool success = IERC20(token).transfer(beneficiary, numTokensDeducted);
        if (success){
            return true;
        } else {
            return false;
        }
    }

    function withdrawAllAvailable(address token) public returns(bool) {
        uint256 amount = ~uint256(0);
        return withdraw(token, amount);
    }
}
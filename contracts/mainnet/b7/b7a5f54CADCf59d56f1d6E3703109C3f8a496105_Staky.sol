/**
 *Submitted for verification at Etherscan.io on 2023-03-01
*/

pragma solidity 0.8.18;
/// SPDX-License-Identifier: MIT


library TransferHelper {

    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor ()  {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract Staky is ReentrancyGuard {

    // Bytes32 is a hash of address + packageID
    // This saves a tremendous amount of gas compared to storing
    // structs (like Unicrypt) 
    mapping(bytes32 => uint256) lockedAmount;
    mapping(bytes32 => uint256) lockedAt;
    mapping(bytes32 => uint256) unlockedAt; 

    // Package stats
    mapping(uint256 => uint256) public packageLocks; // LockTime for packages

    // Protection for setting lock too long
    uint MAX_LOCK_TIME = 32 days;
    
    address public tokenAddress;
    address public dev;
    bool public tokenSet;
    uint256 public packageCount;
    bool public alwaysAllowUnlock;
    bool public burnTaxOn;
    address DEAD = address(0xdead);
    uint256 burnTax = 1; // 0.1%

    constructor() {
        dev = msg.sender;
    }

    modifier onlyDev() {
        require(msg.sender == dev, "Caller is not the dev");
        _;
    }

    function setToken(address t) external onlyDev {
        require(!tokenSet, "token already set");
        tokenAddress = t;
        tokenSet = true;
    }

    function addPackage(uint lockSeconds_) external onlyDev {
        require(lockSeconds_ <= MAX_LOCK_TIME); // Cannot create package with a lock >= 32 days
        unchecked {
            packageCount += 1;
        }
        packageLocks[packageCount] = lockSeconds_;
    }

    // Note, to both add and edit packages
    function editPackage(uint256 PackageID_, uint lockSeconds_) external onlyDev {
        require(PackageID_ <= packageCount, "Package nonexistent");
        require(lockSeconds_ <= MAX_LOCK_TIME);
        packageLocks[PackageID_] = lockSeconds_;
    }

    // In case something goes wrong we can always set all unlockstamps
    // to zero
    function emergencyUnlock() external onlyDev {
        alwaysAllowUnlock = true;
    }

    function resetEmergency() external onlyDev {
        alwaysAllowUnlock = false;
    }

    function shouldBurn(bool _burn) external onlyDev{
        burnTaxOn = _burn;
    }

    function setBurnTax(uint256 _burnTax) external onlyDev {
        require(_burnTax < 100, "tax <10%"); // Divisor is 1000 (see below) so 100/1000*100 = 10%
        burnTax = _burnTax;
    }

    function encode(address sender, uint packageID) internal pure returns (bytes32) {
        // We hash the sender and the package ID
        return(keccak256(abi.encodePacked(sender, packageID)));
    }

    function purchasePackage(uint packageID, uint amount) public nonReentrant {
        // Check if this is a valid package ID
        require(packageID <= packageCount, "Invalid package");
        require(amount > 0, "Amount == 0");

        // Hash sender and the package ID
        bytes32 h = encode(msg.sender, packageID);

        // Transfer tokens from sender to contract
        TransferHelper.safeTransferFrom(tokenAddress, msg.sender, address(this), amount);

        // Check if this is a top up or initial lock
        // if initial lock also store the lockStamp and unlockStamp
        if (lockedAmount[h] == 0) {
            lockedAt[h] = block.timestamp;
            unlockedAt[h] = block.timestamp + packageLocks[packageID];
        }

        // Check if burn tax is enabled, if so burn %
        if (burnTaxOn) {
            uint256 burnAmount = amount * burnTax / 1000;
            amount -= burnAmount;
            TransferHelper.safeTransfer(tokenAddress, address(0xdead), burnAmount);
        }
        
        // Increase total amount of locked tokens
        lockedAmount[h] += amount;
  
    }

    function hasLocked(address who, uint PackageID) public view returns(uint a) {
        a = lockedAmount[encode(who, PackageID)];
    }

    function upgrade(uint PackageIDFrom, uint PackageIDTo) public nonReentrant {
        // Check if valid package ids are given
        require(PackageIDFrom <= packageCount && PackageIDTo <= packageCount, "invalid package");
        require(PackageIDTo > PackageIDFrom, "Not an upgrade");
        
        // Get the hashes for old and new
        bytes32 hashFirst = encode(msg.sender, PackageIDFrom);
        bytes32 hashSecond = encode(msg.sender, PackageIDTo);

        // Check how much there is locked now 
        uint lockedFirst = lockedAmount[hashFirst];

        // Check if something is in the old package
        require(lockedFirst > 0, "Nothing locked here");

        // The new unlockTime depends on the old locktime or whether package 2 already exists
        uint unlockSecond = unlockedAt[hashSecond];
        if (unlockSecond == 0) {
            // create new stamp based on previous package stamp
            unlockedAt[hashSecond] = lockedAt[hashFirst] + packageLocks[PackageIDTo];
            // Also copy the lockstamp from the previous package
            lockedAt[hashSecond] = lockedAt[hashFirst];
        } 

        // Move the token balance
        lockedAmount[hashSecond] += lockedFirst; // top up other package 
  
        // Zero out the old lock and unlock stamp
        lockedAmount[hashFirst] = 0;
        unlockedAt[hashFirst] = 0; 
        lockedAt[hashFirst] = 0;
    }

    function unlockPart(uint PackageID, uint tokensToUnlock) public nonReentrant  {
        require(PackageID <= packageCount); // valid package
        bytes32 h = encode(msg.sender, PackageID);

        // Check if stamp expires
        uint unlocksAt = unlockedAt[h];
        require(unlocksAt <= block.timestamp || alwaysAllowUnlock, "Still locked!");
        
         // Check if something is locked at all and if this is more than 
         // requested to unlock
        uint tokensLocked = lockedAmount[h];
        require(tokensToUnlock <= tokensLocked && tokensToUnlock > 0, "False unlock amount");

        // update the token amount
        lockedAmount[h] -= tokensToUnlock;

        // We might have sent all tokens, in that case reset stamps
        if (tokensToUnlock == tokensLocked) {
            unlockedAt[h] = 0;
            lockedAt[h] = 0;
        }

        // Transfer the part of the tokens
        TransferHelper.safeTransfer(tokenAddress, msg.sender, tokensToUnlock); 
        
    }

    function wenUnlock(address who, uint packageID_) external view returns(uint unlocksAt) {
        unlocksAt = unlockedAt[encode(who, packageID_)];
    }

    function whatLocked(address who, uint packageID) external view returns(uint amount) {
        amount = lockedAmount[encode(who, packageID)];
    }

    function walletInfo(address wallet, uint packageID) external view returns(uint unlocksAt, uint amount) {
        unlocksAt = unlockedAt[encode(wallet, packageID)];
        amount = lockedAmount[encode(wallet, packageID)];
    }

    // In case we/someone would accidently send ETH to the contract
    function withdrawEther() public onlyDev {
        payable(dev).transfer(address(this).balance);
    }

}
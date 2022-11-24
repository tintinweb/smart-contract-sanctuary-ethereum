/**
 *Submitted for verification at Etherscan.io on 2022-11-24
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// File: TheGoldenTurkeyDapp.sol



pragma solidity ^0.8.0;



interface ItokenContract {
    function balanceOf(address account) external view returns (uint256);
}

contract TheGoldenTurkeyDapp is ReentrancyGuard {

    // Basic Variables
    address public owner;
    address theGoldenTurkeyAddress = 0xa75280b84fAC7251D7aFF6B49F4ae5DF5e8Ac900;
    ItokenContract goldenTurkeyContract;

    uint public nextDog = 1;
    uint public nextTurkey = 1;
    uint public nextShield = 1;
    uint public nextSteak = 1;
    uint public nextAttack = 1;
    uint public nextBuyer = 1;
    uint public nextOcurrence = 1;

    uint minimumBalanceForOneTurkey = 200000000000000000;
    uint minimumBalanceForOneDog = 200000000000000000;
    uint minimumBalanceForOneSteak = 300000000000000000;
    uint minimumBalanceForOneShield = 300000000000000000;

    // Structs
    struct dog {
        uint id;
        bool exists;
        uint timeCreated;
        address owner;
        uint nextAvailableAttackDeadline;
        string name;
    }

    struct turkey {
        uint id;
        bool exists;
        uint timeCreated;
        address owner;
        uint shieldActivationEnd;
        string name;
    }

    struct shield {
        uint id;
        bool exists;
        uint timeCreated;
        address owner;
        bool used;
    }

    struct steak {
        uint id;
        bool exists;
        uint timeCreated;
        address owner;
        bool used;
    }

    struct attack {
        uint id;
        bool exists;
        uint timeCreated;
        address attacker;
        uint dogAttacker;
        address target;
        uint turkeyTarget;
    }

    struct buyer {
        uint id; 
        bool exists;
        address user;
        uint deadlineForNextReclaim;
        uint goldenTurkeyWins;
    }

    struct ocurrence {
        uint id;
        bool exists;
        string class;
        address from;
        address to;
        uint time;
    }

    // Mappings
    mapping (uint256 => dog) public Dogs;
    mapping (uint256 => turkey) public Turkeys;
    mapping (uint256 => shield) public Shields;
    mapping (uint256 => steak) public Steaks;
    mapping (uint256 => attack) public Attacks;
    mapping (uint256 => address) public BuyersIdsToAddress;
    mapping (address => buyer) public Buyers;
    mapping(uint256 => ocurrence) public Ocurrences;

    //Modifiers
    modifier onlyOwner {
     require (owner == msg.sender, "Only owner may call this function");
     _;
    }

    constructor() {
        owner = msg.sender;

        goldenTurkeyContract = ItokenContract(theGoldenTurkeyAddress);
    }

    // Helper functions
    receive() external payable {

    }

    function getResources() external {

        address recipient = msg.sender;

        buyer storage newHolder = Buyers[recipient];

        require (block.timestamp > newHolder.deadlineForNextReclaim, "You need to wait 2 hours to reclaim again");
        require (goldenTurkeyContract.balanceOf(recipient) > 200000000000000000, "You need at least 200,000,000 tokens to get resources");


        if (newHolder.exists == false) {
            newHolder.id = nextBuyer;
            newHolder.exists = true;
            newHolder.user = recipient;
            newHolder.deadlineForNextReclaim = newHolder.deadlineForNextReclaim + (2 * 1 hours);

            BuyersIdsToAddress[nextBuyer] = recipient;

            nextBuyer++;

        } else {
            newHolder.deadlineForNextReclaim = newHolder.deadlineForNextReclaim + (2 * 1 hours);
        }

        // Turkeys 
        //uint amountOfTurkeysUserShouldHave = getAmountOfTurkeysUserShouldHave(recipient);
        //uint amountOfTurkeysUserHas = getNumberOfPlayerTurkeys(recipient);
        //uint amountOfTurkeysUserHasLost = getNumberOfTimesPlayerHasBeenAttacked(recipient);

        uint amountOfTurkeysToGet = getAmountOfTurkeysUserShouldHave(recipient) - getNumberOfPlayerTurkeys(recipient) - getNumberOfTimesPlayerHasBeenAttacked(recipient);

        // Dogs
        //uint amountOfDogsUserShouldHave = getAmountOfDogsUserShouldHave(recipient);
        //uint amountOfDogsUserHas = getNumberOfPlayerDogs(recipient);

        uint amountOfDogsToGet = getAmountOfDogsUserShouldHave(recipient) - getNumberOfPlayerDogs(recipient);

        // Steaks
        //uint amountOfSteaksUserShouldHave = getAmountOfSteaksUserShouldHave(recipient);
        //uint amountOfSteaksUserHas = getNumberOfSteaksUserHas(recipient);

        uint amountOfSteakToGet = getAmountOfSteaksUserShouldHave(recipient) - getNumberOfSteaksUserHas(recipient);

        // Shields
        //uint amountOfShieldsUserShouldHave = getAmountOfShieldsUserShouldHave(recipient);
        //uint amountOfShieldsUserHas = getNumberOfShieldsUserHas(recipient);

        uint amountOfShieldsToGet = getAmountOfShieldsUserShouldHave(recipient) - getNumberOfShieldsUserHas(recipient);

        // Get Turkeys
        for (uint i = 0; i < amountOfTurkeysToGet + 1; i++) {
            turkey storage newTurkey = Turkeys[nextTurkey];
            newTurkey.id = nextTurkey;
            newTurkey.exists = true;
            newTurkey.timeCreated = block.timestamp;
            newTurkey.owner = recipient;
            newTurkey.name = "Turkey";

            nextTurkey++;
        }

        // Get Dogs
        for (uint i = 0; i < amountOfDogsToGet + 1; i++) {
            dog storage newDog = Dogs[nextDog];
            newDog.id = nextDog;
            newDog.exists = true;
            newDog.timeCreated = block.timestamp;
            newDog.owner = recipient;
            newDog.name = "Shiba Inu";

            nextDog++;
        }

        // Get Steaks
        for (uint i = 0; i < amountOfSteakToGet + 1; i++) {
            steak storage newSteak = Steaks[nextSteak];
            newSteak.id = nextSteak;
            newSteak.exists = true;
            newSteak.timeCreated = block.timestamp;
            newSteak.owner = recipient;

            nextSteak++;
        }

        // Get Shields
        for (uint i = 0; i < amountOfShieldsToGet + 1; i++) {
            shield storage newShield = Shields[nextShield];
            newShield.id = nextShield;
            newShield.exists = true;
            newShield.timeCreated = block.timestamp;
            newShield.owner = recipient;

            nextShield++;
        }

    }

    function activateShieldForTurkey (uint turkeyId, uint shieldId) external {
        turkey storage shieldedTurkey = Turkeys[turkeyId];
        shield storage shielderShield = Shields[shieldId];
        require (shielderShield.used == false, "Shield already used sir.");
        require (block.timestamp > shieldedTurkey.shieldActivationEnd, "Turkey already protected");
        require (msg.sender == shieldedTurkey.owner, "You're not the owner of this turkey");
        require (msg.sender == shielderShield.owner, "You're not the owner of this shield");

        shieldedTurkey.shieldActivationEnd = block.timestamp + (3 * 1 hours);
        shielderShield.used = true;
    }

    function giveSteakToDog (uint dogId, uint steakId) external {
        dog storage goodBoy = Dogs[dogId];
        steak storage goodSteak = Steaks[steakId];
        require (goodSteak.used == false, "Steak already eaten");

        goodBoy.nextAvailableAttackDeadline = block.timestamp;
        goodSteak.used = true;
    }

    function attackTurkey (uint turkeyId, uint dogId) external {
        turkey storage attackedTurkey = Turkeys[turkeyId];
        dog storage attackerDog = Dogs[dogId];
        require (block.timestamp > attackedTurkey.shieldActivationEnd, "Turkey has a shield protecting him");
        require (block.timestamp > attackerDog.nextAvailableAttackDeadline, "Dog just attacked, he is tired");

        attack storage newAttack = Attacks[nextAttack];
        newAttack.id = nextAttack;
        newAttack.exists = true;
        newAttack.timeCreated = block.timestamp;
        newAttack.attacker = msg.sender;
        newAttack.dogAttacker = dogId;
        newAttack.target = attackedTurkey.owner;
        newAttack.turkeyTarget = turkeyId;

        nextAttack++;

        attackerDog.nextAvailableAttackDeadline = block.timestamp + (3 * 1 hours);

        ocurrence storage newOcurrence = Ocurrences[nextOcurrence];
        newOcurrence.id = nextOcurrence;
        newOcurrence.exists = true;
        newOcurrence.class = "Attack";
        newOcurrence.from = msg.sender;
        newOcurrence.to = newAttack.target;
        newOcurrence.time = block.timestamp;

        attackedTurkey.owner = msg.sender;
    }

    function changeTurkeyName (uint turkeyId, string memory newName) external {
        turkey storage userTurkey = Turkeys[turkeyId];
        require (msg.sender == userTurkey.owner, "You're not the owner of the turkey");

        userTurkey.name = newName;
    }

     function changeDogName (uint dogId, string memory newName) external {
        dog storage userDog = Dogs[dogId];
        require (msg.sender == userDog.owner, "You're not the owner of the turkey");

        userDog.name = newName;
    }

    function changeMinimumBalanceForOneTurkey(uint newBalance) external onlyOwner {
        minimumBalanceForOneTurkey = newBalance;
    }

    function changeMinimumBalanceForOneDog(uint newBalance) external onlyOwner {
        minimumBalanceForOneDog = newBalance;
    }

    function changeMinimumBalanceForOneSteak(uint newBalance) external onlyOwner {
        minimumBalanceForOneSteak = newBalance;
    }

    function changeMinimumBalanceForOneShield(uint newBalance) external onlyOwner {
        minimumBalanceForOneShield = newBalance;
    }

    function getAmountOfTurkeysUserShouldHave(address player) public view returns (uint) {
        uint amountOfTokens = goldenTurkeyContract.balanceOf(player);
        uint amountOfTurkeysUserShouldHave = amountOfTokens / minimumBalanceForOneTurkey;

        return amountOfTurkeysUserShouldHave;
    }

    function getAmountOfDogsUserShouldHave(address player) public view returns (uint) {
        uint amountOfTokens = goldenTurkeyContract.balanceOf(player);
        uint amountOfDogsUserShouldHave = amountOfTokens / minimumBalanceForOneDog;

        return amountOfDogsUserShouldHave;
    }

    function getAmountOfSteaksUserShouldHave(address player) public view returns (uint) {
        uint amountOfTokens = goldenTurkeyContract.balanceOf(player);
        uint amountOfSteaksUserShouldHave = amountOfTokens / minimumBalanceForOneSteak;

        return amountOfSteaksUserShouldHave;
    }

    function getUserSteaks(address player) public view returns (steak[] memory filteredSteaks) {
        steak[] memory steaksTemp = new steak[](nextSteak - 1);
        uint count;
        for (uint i = 0; i < (nextShield - 1); i++) {
            if (Steaks[i].owner == player && Steaks[i].used == false) {
                steaksTemp[count] = Steaks[i];
                count++;
            }
        }

        filteredSteaks = new steak[](count);
        for (uint i = 0; i < count; i++) {
            filteredSteaks[i] = steaksTemp[i];
        }

        return filteredSteaks;
    }

    function getNumberOfSteaksUserHas(address player) public view returns (uint) {
        steak[] memory steaks = getUserSteaks(player);
        return steaks.length;
    }

    function getAmountOfShieldsUserShouldHave(address player) public view returns (uint) {
        uint amountOfTokens = goldenTurkeyContract.balanceOf(player);
        uint amountOfShieldsUserShouldHave = amountOfTokens / minimumBalanceForOneShield;

        return amountOfShieldsUserShouldHave;
    }

    function getUserShields(address player) public view returns (shield[] memory filteredShields) {
        shield[] memory shieldsTemp = new shield[](nextShield - 1);
        uint count;
        for (uint i = 0; i < (nextShield- 1); i++) {
            if (Shields[i].owner == player && Shields[i].used == false) {
                shieldsTemp[count] = Shields[i];
                count++;
            }
        }

        filteredShields = new shield[](count);
        for (uint i = 0; i < count; i++) {
            filteredShields[i] = shieldsTemp[i];
        }

        return filteredShields;
    }

    function getNumberOfShieldsUserHas(address player) public view returns (uint) {
        shield[] memory shields = getUserShields(player);
        return shields.length;
    }

    function getTimesPlayerHasBeenAttacked(address player) public view returns (attack[] memory filteredAttacks) {
        attack[] memory attacksTemp = new attack[](nextAttack - 1);
        uint count;
        for (uint i = 0; i < (nextAttack - 1); i++) {
            if (Attacks[i].target == player) {
                attacksTemp[count] = Attacks[i];
                count++;
            }
        }

        filteredAttacks = new attack[](count);
        for (uint i = 0; i < count; i++) {
            filteredAttacks[i] = attacksTemp[i];
        }

        return filteredAttacks;
    }

    function getNumberOfTimesPlayerHasBeenAttacked(address player) public view returns (uint) {
        attack[] memory attacks = getTimesPlayerHasBeenAttacked(player);
        return attacks.length;
    }

    function getTimesPlayerHasAttacked(address player) public view returns (attack[] memory filteredAttacks) {
        attack[] memory attacksTemp = new attack[](nextAttack - 1);
        uint count;
        for (uint i = 0; i < (nextAttack - 1); i++) {
            if (Attacks[i].attacker == player) {
                attacksTemp[count] = Attacks[i];
                count++;
            }
        }

        filteredAttacks = new attack[](count);
        for (uint i = 0; i < count; i++) {
            filteredAttacks[i] = attacksTemp[i];
        }

        return filteredAttacks;
    }

    function getNumberOfTimesPlayerHasAttacked(address player) public view returns (uint) {
        attack[] memory attacks = getTimesPlayerHasAttacked(player);
        return attacks.length;
    }

    function getPlayerTurkeys(address player) public view returns (turkey[] memory filteredTurkeys) {
        turkey[] memory turkeysTemp = new turkey[](nextTurkey - 1);
        uint count;
        for (uint i = 0; i < (nextTurkey -1); i++) {
            if (Turkeys[i].owner == player) {
                turkeysTemp[count] = Turkeys[i];
                count++;
            }
        }

        filteredTurkeys = new turkey[](count);
        for (uint i = 0; i < count; i++) {
            filteredTurkeys[i] = turkeysTemp[i];
        }

        return filteredTurkeys;
    }

    function getNumberOfPlayerTurkeys(address player) public view returns (uint) {
        turkey[] memory turkeys = getPlayerTurkeys(player);
        return turkeys.length;
    }

    function getPlayerDogs(address player) public view returns (dog[] memory filteredDogs) {
        dog[] memory dogsTemp = new dog[](nextDog - 1);
        uint count;
        for (uint i = 0; i < (nextDog -1); i++) {
            if (Dogs[i].owner == player) {
                dogsTemp[count] = Dogs[i];
                count++;
            }
        }

        filteredDogs = new dog[](count);
        for (uint i = 0; i < count; i++) {
            filteredDogs[i] = dogsTemp[i];
        }

        return filteredDogs;
    }

    function getNumberOfPlayerDogs(address player) public view returns (uint) {
        dog[] memory dogs = getPlayerDogs(player);
        return dogs.length;
    }

    function payWinner(address winner, uint amount) external onlyOwner {
        buyer storage theWinner = Buyers[winner];
        theWinner.goldenTurkeyWins++;

        payable(winner).call{value: amount}("");
    }

    function withdrawEth() external onlyOwner {
          (bool os,) = payable(owner).call{value:address(this).balance}("");
          require(os);
     }

}
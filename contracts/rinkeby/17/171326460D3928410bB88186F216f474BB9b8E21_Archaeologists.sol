// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./Utils.sol";
import "./Events.sol";
import "./Types.sol";
import "./Datas.sol";

/**
 * @title A library implementing Archaeologist-specific logic in the
 * Sarcophagus system
 * @notice This library includes public functions for manipulating
 * archaeologists in the Sarcophagus system
 */
library Archaeologists {
    /**
     * @notice Checks that an archaeologist exists, or doesn't exist, and
     * and reverts if necessary
     * @param data the system's data struct instance
     * @param account the archaeologist address to check existence of
     * @param exists bool which flips whether function reverts if archaeologist
     * exists or not
     */
    function archaeologistExists(
        Datas.Data storage data,
        address account,
        bool exists
    ) public view {
        // set the error message
        string memory err = "archaeologist has not been registered yet";
        if (!exists) err = "archaeologist has already been registered";

        // revert if necessary
        require(data.archaeologists[account].exists == exists, err);
    }

    /**
     * @notice Increases internal data structure which tracks free bond per
     * archaeologist
     * @param data the system's data struct instance
     * @param archAddress the archaeologist's address to operate on
     * @param amount the amount to increase free bond by
     */
    function increaseFreeBond(
        Datas.Data storage data,
        address archAddress,
        uint256 amount
    ) private {
        // load up the archaeologist
        Types.Archaeologist storage arch = data.archaeologists[archAddress];

        // increase the freeBond variable by amount
        arch.freeBond = arch.freeBond + amount;
    }

    /**
     * @notice Decreases internal data structure which tracks free bond per
     * archaeologist
     * @param data the system's data struct instance
     * @param archAddress the archaeologist's address to operate on
     * @param amount the amount to decrease free bond by
     */
    function decreaseFreeBond(
        Datas.Data storage data,
        address archAddress,
        uint256 amount
    ) private {
        // load up the archaeologist
        Types.Archaeologist storage arch = data.archaeologists[archAddress];

        // decrease the free bond variable by amount, reverting if necessary
        require(
            arch.freeBond >= amount,
            "archaeologist does not have enough free bond"
        );
        arch.freeBond = arch.freeBond - amount;
    }

    /**
     * @notice Increases internal data structure which tracks cursed bond per
     * archaeologist
     * @param data the system's data struct instance
     * @param archAddress the archaeologist's address to operate on
     * @param amount the amount to increase cursed bond by
     */
    function increaseCursedBond(
        Datas.Data storage data,
        address archAddress,
        uint256 amount
    ) private {
        // load up the archaeologist
        Types.Archaeologist storage arch = data.archaeologists[archAddress];

        // increase the freeBond variable by amount
        arch.cursedBond = arch.cursedBond + amount;
    }

    /**
     * @notice Decreases internal data structure which tracks cursed bond per
     * archaeologist
     * @param data the system's data struct instance
     * @param archAddress the archaeologist's address to operate on
     * @param amount the amount to decrease cursed bond by
     */
    function decreaseCursedBond(
        Datas.Data storage data,
        address archAddress,
        uint256 amount
    ) public {
        // load up the archaeologist
        Types.Archaeologist storage arch = data.archaeologists[archAddress];

        // decrease the free bond variable by amount
        arch.cursedBond = arch.cursedBond - amount;
    }

    /**
     * @notice Given an archaeologist and amount, decrease free bond and
     * increase cursed bond
     * @param data the system's data struct instance
     * @param archAddress the archaeologist's address to operate on
     * @param amount the amount to decrease free bond and increase cursed bond
     */
    function lockUpBond(
        Datas.Data storage data,
        address archAddress,
        uint256 amount
    ) public {
        decreaseFreeBond(data, archAddress, amount);
        increaseCursedBond(data, archAddress, amount);
    }

    /**
     * @notice Given an archaeologist and amount, increase free bond and
     * decrease cursed bond
     * @param data the system's data struct instance
     * @param archAddress the archaeologist's address to operate on
     * @param amount the amount to increase free bond and decrease cursed bond
     */
    function freeUpBond(
        Datas.Data storage data,
        address archAddress,
        uint256 amount
    ) public {
        increaseFreeBond(data, archAddress, amount);
        decreaseCursedBond(data, archAddress, amount);
    }

    /**
     * @notice Calculates and returns the curse for any sarcophagus
     * @param diggingFee the digging fee of a sarcophagus
     * @param bounty the bounty of a sarcophagus
     * @return amount of the curse
     * @dev Current implementation simply adds the two inputs together. Future
     * strategies should use historical data to build a curve to change this
     * amount over time.
     */
    function getCursedBond(uint256 diggingFee, uint256 bounty)
        public
        pure
        returns (uint256)
    {
        // TODO: implment a better algorithm, using some concept of past state
        return diggingFee + bounty;
    }

    /**
     * @notice Registers a new archaeologist in the system
     * @param data the system's data struct instance
     * @param currentPublicKey the public key to be used in the first
     * sarcophagus
     * @param endpoint where to contact this archaeologist on the internet
     * @param paymentAddress all collected payments for the archaeologist will
     * be sent here
     * @param feePerByte amount of SARCO tokens charged per byte of storage
     * being sent to Arweave
     * @param minimumBounty the minimum bounty for a sarcophagus that the
     * archaeologist will accept
     * @param minimumDiggingFee the minimum digging fee for a sarcophagus that
     * the archaeologist will accept
     * @param maximumResurrectionTime the maximum resurrection time for a
     * sarcophagus that the archaeologist will accept, in relative terms (i.e.
     * "1 year" is 31536000 (seconds))
     * @param freeBond the amount of SARCO bond that the archaeologist wants
     * to start with
     * @param sarcoToken the SARCO token used for payment handling
     * @return index of the new archaeologist
     */
    function registerArchaeologist(
        Datas.Data storage data,
        bytes memory currentPublicKey,
        string memory endpoint,
        address paymentAddress,
        uint256 feePerByte,
        uint256 minimumBounty,
        uint256 minimumDiggingFee,
        uint256 maximumResurrectionTime,
        uint256 freeBond,
        IERC20 sarcoToken
    ) public returns (uint256) {
        // verify that the archaeologist does not already exist
        archaeologistExists(data, msg.sender, false);

        // verify that the public key length is accurate
        Utils.publicKeyLength(currentPublicKey);

        // transfer SARCO tokens from the archaeologist to this contract, to be
        // used as their free bond. can be 0, which indicates that the
        // archaeologist is not eligible for any new jobs
        if (freeBond > 0) {
            sarcoToken.transferFrom(msg.sender, address(this), freeBond);
        }

        // create a new archaeologist
        Types.Archaeologist memory newArch =
            Types.Archaeologist({
                exists: true,
                currentPublicKey: currentPublicKey,
                endpoint: endpoint,
                paymentAddress: paymentAddress,
                feePerByte: feePerByte,
                minimumBounty: minimumBounty,
                minimumDiggingFee: minimumDiggingFee,
                maximumResurrectionTime: maximumResurrectionTime,
                freeBond: freeBond,
                cursedBond: 0
            });

        // save the new archaeologist into relevant data structures
        data.archaeologists[msg.sender] = newArch;
        data.archaeologistAddresses.push(msg.sender);

        // emit an event
        emit Events.RegisterArchaeologist(
            msg.sender,
            newArch.currentPublicKey,
            newArch.endpoint,
            newArch.paymentAddress,
            newArch.feePerByte,
            newArch.minimumBounty,
            newArch.minimumDiggingFee,
            newArch.maximumResurrectionTime,
            newArch.freeBond
        );

        // return index of the new archaeologist
        return data.archaeologistAddresses.length - 1;
    }

    /**
     * @notice An archaeologist may update their profile
     * @param data the system's data struct instance
     * @param endpoint where to contact this archaeologist on the internet
     * @param newPublicKey the public key to be used in the next
     * sarcophagus
     * @param paymentAddress all collected payments for the archaeologist will
     * be sent here
     * @param feePerByte amount of SARCO tokens charged per byte of storage
     * being sent to Arweave
     * @param minimumBounty the minimum bounty for a sarcophagus that the
     * archaeologist will accept
     * @param minimumDiggingFee the minimum digging fee for a sarcophagus that
     * the archaeologist will accept
     * @param maximumResurrectionTime the maximum resurrection time for a
     * sarcophagus that the archaeologist will accept, in relative terms (i.e.
     * "1 year" is 31536000 (seconds))
     * @param freeBond the amount of SARCO bond that the archaeologist wants
     * to add to their profile
     * @param sarcoToken the SARCO token used for payment handling
     * @return bool indicating that the update was successful
     */
    function updateArchaeologist(
        Datas.Data storage data,
        bytes memory newPublicKey,
        string memory endpoint,
        address paymentAddress,
        uint256 feePerByte,
        uint256 minimumBounty,
        uint256 minimumDiggingFee,
        uint256 maximumResurrectionTime,
        uint256 freeBond,
        IERC20 sarcoToken
    ) public returns (bool) {
        // verify that the archaeologist exists, and is the sender of this
        // transaction
        archaeologistExists(data, msg.sender, true);

        // load up the archaeologist
        Types.Archaeologist storage arch = data.archaeologists[msg.sender];

        // if archaeologist is updating their active public key, emit an event
        if (keccak256(arch.currentPublicKey) != keccak256(newPublicKey)) {
            emit Events.UpdateArchaeologistPublicKey(msg.sender, newPublicKey);
            arch.currentPublicKey = newPublicKey;
        }

        // update the rest of the archaeologist profile
        arch.endpoint = endpoint;
        arch.paymentAddress = paymentAddress;
        arch.feePerByte = feePerByte;
        arch.minimumBounty = minimumBounty;
        arch.minimumDiggingFee = minimumDiggingFee;
        arch.maximumResurrectionTime = maximumResurrectionTime;

        // the freeBond variable acts as an incrementer, so only if it's above
        // zero will we update their profile variable and transfer the tokens
        if (freeBond > 0) {
            increaseFreeBond(data, msg.sender, freeBond);
            sarcoToken.transferFrom(msg.sender, address(this), freeBond);
        }

        // emit an event
        emit Events.UpdateArchaeologist(
            msg.sender,
            arch.endpoint,
            arch.paymentAddress,
            arch.feePerByte,
            arch.minimumBounty,
            arch.minimumDiggingFee,
            arch.maximumResurrectionTime,
            freeBond
        );

        // return true
        return true;
    }

    /**
     * @notice Archaeologist can withdraw any of their free bond
     * @param data the system's data struct instance
     * @param amount the amount of the archaeologist's free bond that they're
     * withdrawing
     * @param sarcoToken the SARCO token used for payment handling
     * @return bool indicating that the withdrawal was successful
     */
    function withdrawBond(
        Datas.Data storage data,
        uint256 amount,
        IERC20 sarcoToken
    ) public returns (bool) {
        // verify that the archaeologist exists, and is the sender of this
        // transaction
        archaeologistExists(data, msg.sender, true);

        // move free bond out of the archaeologist
        decreaseFreeBond(data, msg.sender, amount);

        // transfer the freed SARCOs back to the archaeologist
        sarcoToken.transfer(msg.sender, amount);

        // emit event
        emit Events.WithdrawalFreeBond(msg.sender, amount);

        // return true
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Utility functions used within the Sarcophagus system
 * @notice This library implements various functions that are used throughout
 * Sarcophagus, mainly to DRY up the codebase
 * @dev these functions are all stateless, public, pure/view
 */
library Utils {
    /**
     * @notice Reverts if the public key length is not exactly 64 bytes long
     * @param publicKey the key to check length of
     */
    function publicKeyLength(bytes memory publicKey) public pure {
        require(publicKey.length == 64, "public key must be 64 bytes");
    }

    /**
     * @notice Reverts if the hash of singleHash does not equal doubleHash
     * @param doubleHash the hash to compare hash of singleHash to
     * @param singleHash the value to hash and compare against doubleHash
     */
    function hashCheck(bytes32 doubleHash, bytes memory singleHash)
        public
        pure
    {
        require(doubleHash == keccak256(singleHash), "hashes do not match");
    }

    /**
     * @notice Reverts if the input string is not empty
     * @param assetId the string to check
     */
    function confirmAssetIdNotSet(string memory assetId) public pure {
        require(bytes(assetId).length == 0, "assetId has already been set");
    }

    /**
     * @notice Reverts if existing assetId is not empty, or if new assetId is
     * @param existingAssetId the orignal assetId to check, make sure is empty
     * @param newAssetId the new assetId, which must not be empty
     */
    function assetIdsCheck(
        string memory existingAssetId,
        string memory newAssetId
    ) public pure {
        // verify that the existingAssetId is currently empty
        confirmAssetIdNotSet(existingAssetId);

        require(bytes(newAssetId).length > 0, "assetId must not have 0 length");
    }

    /**
     * @notice Reverts if the given data and signature did not come from the
     * given address
     * @param data the payload which has been signed
     * @param v signature element
     * @param r signature element
     * @param s signature element
     * @param account address to confirm data and signature came from
     */
    function signatureCheck(
        bytes memory data,
        uint8 v,
        bytes32 r,
        bytes32 s,
        address account
    ) public pure {
        // generate the address for a given data and signature
        address hopefulAddress = ecrecover(keccak256(data), v, r, s);

        require(
            hopefulAddress == account,
            "signature did not come from correct account"
        );
    }

    /**
     * @notice Reverts if the given resurrection time is not in the future
     * @param resurrectionTime the time to check against block.timestamp
     */
    function resurrectionInFuture(uint256 resurrectionTime) public view {
        require(
            resurrectionTime > block.timestamp,
            "resurrection time must be in the future"
        );
    }

    /**
     * @notice Calculates the grace period that an archaeologist has after a
     * sarcophagus has reached its resurrection time
     * @param resurrectionTime the resurrection timestamp of a sarcophagus
     * @return the grace period
     * @dev The grace period is dependent on how far out the resurrection time
     * is. The longer out the resurrection time, the longer the grace period.
     * There is a minimum grace period of 30 minutes, otherwise, it's
     * calculated as 1% of the time between now and resurrection time.
     */
    function getGracePeriod(uint256 resurrectionTime)
        public
        view
        returns (uint256)
    {
        // set a minimum window of 30 minutes
        uint32 minimumResurrectionWindow = 1440 minutes;

        // calculate 1% of the relative time between now and the resurrection
        // time
        uint256 gracePeriod = (resurrectionTime - block.timestamp) / 100;

        // if our calculated grace period is less than the minimum time, we'll
        // use the minimum time instead
        if (gracePeriod < minimumResurrectionWindow) {
            gracePeriod = minimumResurrectionWindow;
        }

        // return that grace period
        return gracePeriod;
    }

    /**
     * @notice Reverts if we're not within the resurrection window (on either
     * side)
     * @param resurrectionTime the resurrection time of the sarcophagus
     * (absolute, i.e. a date time stamp)
     * @param resurrectionWindow the resurrection window of the sarcophagus
     * (relative, i.e. "30 minutes")
     */
    function unwrapTime(uint256 resurrectionTime, uint256 resurrectionWindow)
        public
        view
    {
        // revert if too early
        require(
            resurrectionTime <= block.timestamp,
            "it's not time to unwrap the sarcophagus"
        );

        // revert if too late
        require(
            resurrectionTime + resurrectionWindow >= block.timestamp,
            "the resurrection window has expired"
        );
    }

    /**
     * @notice Reverts if msg.sender is not equal to passed-in address
     * @param account the account to verify is msg.sender
     */
    function sarcophagusUpdater(address account) public view {
        require(
            account == msg.sender,
            "sarcophagus cannot be updated by account"
        );
    }

    /**
     * @notice Reverts if the input resurrection time, digging fee, or bounty
     * don't fit within the other given maximum and minimum values
     * @param resurrectionTime the resurrection time to check
     * @param diggingFee the digging fee to check
     * @param bounty the bounty to check
     * @param maximumResurrectionTime the maximum resurrection time to check
     * against, in relative terms (i.e. "1 year" is 31536000 (seconds))
     * @param minimumDiggingFee the minimum digging fee to check against
     * @param minimumBounty the minimum bounty to check against
     */
    function withinArchaeologistLimits(
        uint256 resurrectionTime,
        uint256 diggingFee,
        uint256 bounty,
        uint256 maximumResurrectionTime,
        uint256 minimumDiggingFee,
        uint256 minimumBounty
    ) public view {
        // revert if the given resurrection time is too far in the future
        require(
            resurrectionTime <= block.timestamp + maximumResurrectionTime,
            "resurrection time too far in the future"
        );

        // revert if the given digging fee is too low
        require(diggingFee >= minimumDiggingFee, "digging fee is too low");

        // revert if the given bounty is too low
        require(bounty >= minimumBounty, "bounty is too low");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title A collection of defined structs
 * @notice This library defines the various data models that the Sarcophagus
 * system uses
 */
library Types {
    struct Archaeologist {
        bool exists;
        bytes currentPublicKey;
        string endpoint;
        address paymentAddress;
        uint256 feePerByte;
        uint256 minimumBounty;
        uint256 minimumDiggingFee;
        uint256 maximumResurrectionTime;
        uint256 freeBond;
        uint256 cursedBond;
    }

    enum SarcophagusStates {DoesNotExist, Exists, Done}

    struct Sarcophagus {
        SarcophagusStates state;
        address archaeologist;
        bytes archaeologistPublicKey;
        address embalmer;
        string name;
        uint256 resurrectionTime;
        uint256 resurrectionWindow;
        string assetId;
        bytes recipientPublicKey;
        uint256 storageFee;
        uint256 diggingFee;
        uint256 bounty;
        uint256 currentCursedBond;
        bytes32 privateKey;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title A collection of Events
 * @notice This library defines all of the Events that the Sarcophagus system
 * emits
 */
library Events {
    event Creation(address sarcophagusContract);

    event RegisterArchaeologist(
        address indexed archaeologist,
        bytes currentPublicKey,
        string endpoint,
        address paymentAddress,
        uint256 feePerByte,
        uint256 minimumBounty,
        uint256 minimumDiggingFee,
        uint256 maximumResurrectionTime,
        uint256 bond
    );

    event UpdateArchaeologist(
        address indexed archaeologist,
        string endpoint,
        address paymentAddress,
        uint256 feePerByte,
        uint256 minimumBounty,
        uint256 minimumDiggingFee,
        uint256 maximumResurrectionTime,
        uint256 addedBond
    );

    event UpdateArchaeologistPublicKey(
        address indexed archaeologist,
        bytes currentPublicKey
    );

    event WithdrawalFreeBond(
        address indexed archaeologist,
        uint256 withdrawnBond
    );

    event CreateSarcophagus(
        bytes32 indexed identifier,
        address indexed archaeologist,
        bytes archaeologistPublicKey,
        address embalmer,
        string name,
        uint256 resurrectionTime,
        uint256 resurrectionWindow,
        uint256 storageFee,
        uint256 diggingFee,
        uint256 bounty,
        bytes recipientPublicKey,
        uint256 cursedBond
    );

    event UpdateSarcophagus(bytes32 indexed identifier, string assetId);

    event CancelSarcophagus(bytes32 indexed identifier);

    event RewrapSarcophagus(
        string assetId,
        bytes32 indexed identifier,
        uint256 resurrectionTime,
        uint256 resurrectionWindow,
        uint256 diggingFee,
        uint256 bounty,
        uint256 cursedBond
    );

    event UnwrapSarcophagus(
        string assetId,
        bytes32 indexed identifier,
        bytes32 privatekey
    );

    event AccuseArchaeologist(
        bytes32 indexed identifier,
        address indexed accuser,
        uint256 accuserBondReward,
        uint256 embalmerBondReward
    );

    event BurySarcophagus(bytes32 indexed identifier);

    event CleanUpSarcophagus(
        bytes32 indexed identifier,
        address indexed cleaner,
        uint256 cleanerBondReward,
        uint256 embalmerBondReward
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Types.sol";

/**
 * @title A library implementing data structures for the Sarcophagus system
 * @notice This library defines a Data struct, which defines all of the state
 * that the Sarcophagus system needs to operate. It's expected that a single
 * instance of this state will exist.
 */
library Datas {
    struct Data {
        // archaeologists
        address[] archaeologistAddresses;
        mapping(address => Types.Archaeologist) archaeologists;
        // archaeologist stats
        mapping(address => bytes32[]) archaeologistSuccesses;
        mapping(address => bytes32[]) archaeologistCancels;
        mapping(address => bytes32[]) archaeologistAccusals;
        mapping(address => bytes32[]) archaeologistCleanups;
        // archaeologist key control
        mapping(bytes => bool) archaeologistUsedKeys;
        // sarcophaguses
        bytes32[] sarcophagusIdentifiers;
        mapping(bytes32 => Types.Sarcophagus) sarcophaguses;
        // sarcophagus ownerships
        mapping(address => bytes32[]) embalmerSarcophaguses;
        mapping(address => bytes32[]) archaeologistSarcophaguses;
        mapping(address => bytes32[]) recipientSarcophaguses;
    }
}
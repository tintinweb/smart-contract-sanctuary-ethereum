// SPDX-License-Identifier: GPL-3.0
// solhint-disable-next-line
pragma solidity 0.8.12;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./reduced_interfaces/BAPGenesisInterface.sol";
import "./reduced_interfaces/BAPMethaneInterface.sol";
import "./reduced_interfaces/BAPUtilitiesInterface.sol";
import "./reduced_interfaces/BAPTeenBullsInterface.sol";
import "./reduced_interfaces/BAPOrchestratorInterfaceV2.sol";
import "./IERC721Receiver.sol";

contract BAPOrchestratorV3 is Ownable, IERC721Receiver {
    string public constant project = "Bulls & Apes Project";

    uint256 public constant startTime = 1665291600;
    uint256 public timeCounter = 1 days;
    uint256 public powerCooldown = 14 days;
    uint256 private lastTokenReceived;

    address public treasuryWallet;
    address public secret;

    bool public claimFlag = true;
    bool public refundFlag = false;
    bool private isReviving = false;

    mapping(uint256 => uint256) public breedingsLeft;
    mapping(uint256 => uint256) public claimedMeth;
    mapping(uint256 => uint256) public claimedTeenMeth;
    mapping(uint256 => uint256) public lastChestOpen;

    mapping(uint256 => bool) public isGod;
    mapping(uint256 => bool) public prevClaimed;

    mapping(address => uint256) public userLastClaim;

    BAPGenesisInterface public bapGenesis;
    BAPMethaneInterface public bapMeth;
    BAPUtilitiesInterface public bapUtilities;
    BAPTeenBullsInterface public bapTeenBulls;
    BAPOrchestratorInterfaceV2 public bapOrchestratorV2;

    event CHEST_OPENED(
        uint256 num,
        uint256 godId,
        uint256 prize,
        uint256 timestamp
    );
    event METH_CLAIMED(address user, uint256 amount, uint256 timestamp);
    event GOD_MINTED(address user, uint256 id, uint256 timestamp);
    event TEEN_RESURRECTED(
        address user,
        uint256 sacrificed,
        uint256 resurrected,
        uint256 newlyMinted
    );

    constructor(
        address _bapGenesis,
        address _bapMethane,
        address _bapUtilities,
        address _bapTeenBulls,
        address _orchestratorV2
    ) {
        bapGenesis = BAPGenesisInterface(_bapGenesis);
        bapMeth = BAPMethaneInterface(_bapMethane);
        bapUtilities = BAPUtilitiesInterface(_bapUtilities);
        bapTeenBulls = BAPTeenBullsInterface(_bapTeenBulls);
        bapOrchestratorV2 = BAPOrchestratorInterfaceV2(_orchestratorV2);
    }

    modifier noZeroAddress(address _address) {
        require(_address != address(0), "200:ZERO_ADDRESS");
        _;
    }

    // WRITE FUNCTIONS

    function claimMeth(
        uint256[] memory bulls,
        uint256[] memory gods,
        uint256[] memory teens
    ) public {
        require(claimFlag, "Claim is disabled");

        uint256 claimableMeth;

        for (uint256 i; i < bulls.length; i++) {
            claimableMeth += _claimMeth(bulls[i], 0);
        }
        for (uint256 i; i < gods.length; i++) {
            require(godBulls(gods[i]), "Not a god bull");
            claimableMeth += _claimMeth(gods[i], 1);
        }
        for (uint256 i; i < teens.length; i++) {
            require(isResurrected(teens[i]), "Not a resurrected teen");
            claimableMeth += _claimMeth(teens[i], 2);
        }

        bapMeth.claim(msg.sender, claimableMeth);
    }

    function generateTeenBull() public {
        bapMeth.pay(600, 300);
        bapUtilities.burn(1, 1);
        bapTeenBulls.generateTeenBull();
    }

    function generateGodBull(
        bytes memory signature,
        uint256 bull1,
        uint256 bull2,
        uint256 bull3,
        uint256 bull4
    ) public {
        require(
            _verifyHashSignature(
                keccak256(abi.encode(msg.sender, bull1, bull2, bull3, bull4)),
                signature
            ),
            "Signature is invalid"
        );
        bapMeth.pay(4800, 2400);
        bapUtilities.burn(2, 1);
        _burnTeen(bull1);
        _burnTeen(bull2);
        _burnTeen(bull3);
        _burnTeen(bull4);

        uint256 id = bapGenesis.minted() + 1;
        prevClaimed[id] = true;
        claimedMeth[id] = getClaimableMeth(id, 1);

        bapGenesis.generateGodBull();

        emit GOD_MINTED(msg.sender, id, block.timestamp);
    }

    function buyIncubator(
        bytes memory signature,
        uint256 bull1,
        uint256 bull2
    ) public {
        require(
            _verifyHashSignature(
                keccak256(abi.encode(msg.sender, bull1, bull2)),
                signature
            ),
            "Signature is invalid"
        );
        bapMeth.pay(600, 300);
        _breedToken(bull1);
        _breedToken(bull2);
        bapUtilities.purchaseIncubator();
    }

    function buyMergeOrb(uint256 teen) public {
        bapMeth.pay(2400, 1200);
        _burnTeen(teen);
        bapUtilities.purchaseMergerOrb();
    }

    function refund(uint256 tokenId) external noZeroAddress(treasuryWallet) {
        require(availableForRefund(tokenId), "Token not available for refund");

        bapGenesis.refund(msg.sender, tokenId);
        bapGenesis.safeTransferFrom(msg.sender, treasuryWallet, tokenId);
    }

    // NEW FUNCTIONS
    function openChest(
        uint256 godId,
        uint256 guild,
        uint256 seed,
        bool hasPower,
        bytes memory signature
    ) external {
        require(seed > block.timestamp, "Seed is no longer valid");
        require(
            _verifyHashSignature(
                keccak256(abi.encode(msg.sender, godId, guild, seed, hasPower)),
                signature
            ),
            "Signature is invalid"
        );
        require(bapGenesis.ownerOf(godId) == msg.sender, "Not the god owner");
        require(godBulls(godId), "Not a god bull");

        if (
            !hasPower || lastChestOpen[godId] + powerCooldown > block.timestamp
        ) {
            require(
                lastChestOpen[godId] + 20 minutes > block.timestamp,
                "Re open time elapsed"
            );

            bapMeth.pay(1200, 1200);
            lastChestOpen[godId] = block.timestamp - 21 minutes;
        } else {
            bapMeth.pay(600, 600);
            lastChestOpen[godId] = block.timestamp;
        }

        uint256 num = random(seed) % 100;
        uint256 prize;

        if (num < 10) {
            prize = 20 + guild;
            bapUtilities.airdrop(msg.sender, 1, (prize)); // UTILITIE #20 - 23 METH MAKER - 10%
        } else if (num < 40) {
            prize = 30 + guild;
            bapUtilities.airdrop(msg.sender, 1, (prize)); // UTILITIE #30 - 33 RESURRECTION - 30%
        } else {
            prize = 40 + guild;
            bapUtilities.airdrop(msg.sender, 1, (prize)); // UTILITIE #40 - 43 BREED REPLENISH - 60%
        }

        emit CHEST_OPENED(num, godId, prize, block.timestamp);
    }

    function useItem(
        uint256 item,
        uint256 tokenId,
        uint256 godId,
        uint256 resurrected,
        bytes memory signature
    ) external {
        require(
            _verifyHashSignature(
                keccak256(
                    abi.encode(msg.sender, item, tokenId, godId, resurrected)
                ),
                signature
            ),
            "Signature is invalid"
        );

        bapUtilities.burn(item, 1); // #30 - 33 RESURRECTION, #40 - 43 BREED REPLENISH

        if (item >= 30 && item < 35) {
            require(godBulls(godId), "You need to use a good");
            require(
                bapGenesis.ownerOf(godId) == msg.sender,
                "Not the god owner"
            );

            _burnTeen(tokenId);

            isReviving = true;

            bapTeenBulls.airdrop(address(this), 1);
            claimedTeenMeth[lastTokenReceived] = getClaimableMeth(
                lastTokenReceived,
                2
            );

            isReviving = false;

            bapTeenBulls.safeTransferFrom(
                address(this),
                msg.sender,
                lastTokenReceived
            );

            emit TEEN_RESURRECTED(
                msg.sender,
                tokenId,
                resurrected,
                lastTokenReceived
            );

            lastTokenReceived = 0;
        } else if (item >= 40 && item < 45) {
            require(
                bapGenesis.ownerOf(tokenId) == msg.sender,
                "Only the owner can replenish"
            );
            require(
                !godBulls(tokenId),
                "God bulls cannot claim extra breeding"
            );

            uint256 currentBreeds = breedings(tokenId);

            require(currentBreeds < 3, "Bull has all breeds available");

            breedingsLeft[tokenId] = 3 - currentBreeds;
        } else {
            require(false, "Wrong item id");
        }
    }

    function claimTeenMeth(
        uint256 amount,
        uint256 seed,
        bytes memory signature
    ) public {
        require(seed > block.timestamp, "Seed is no longer valid");
        require(
            userLastClaim[msg.sender] + 1 days < block.timestamp,
            "Can claim only once a day"
        );
        require(
            _verifyHashSignature(
                keccak256(abi.encode(amount, seed, msg.sender)),
                signature
            ),
            "Signature is invalid"
        );

        userLastClaim[msg.sender] = block.timestamp;

        bapMeth.claim(msg.sender, amount);

        emit METH_CLAIMED(msg.sender, amount, block.timestamp);
    }

    // BULK FUNCTIONS

    function claimAllMeth(
        uint256[] memory bulls,
        uint256[] memory gods,
        uint256[] memory teens,
        uint256 amount,
        uint256 seed,
        bytes memory signature
    ) external {
        claimMeth(bulls, gods, teens);
        claimTeenMeth(amount, seed, signature);
    }

    function breedAndIncubate(
        bytes memory signature,
        uint256 bull1,
        uint256 bull2
    ) external {
        buyIncubator(signature, bull1, bull2);
        generateTeenBull();
    }

    function buyOrbAndSummon(
        uint256 teen,
        bytes memory signature,
        uint256 bull1,
        uint256 bull2,
        uint256 bull3,
        uint256 bull4
    ) external {
        buyMergeOrb(teen);
        generateGodBull(signature, bull1, bull2, bull3, bull4);
    }

    // INTERNAL FUNCTIONS

    function _claimMeth(uint256 tokenId, uint256 _type)
        internal
        returns (uint256 amount)
    {
        amount = getClaimableMeth(tokenId, _type);

        if (_type == 2) {
            require(
                bapTeenBulls.ownerOf(tokenId) == msg.sender,
                "Only the owner can claim"
            );

            claimedTeenMeth[tokenId] += amount;
        } else {
            require(
                bapGenesis.ownerOf(tokenId) == msg.sender,
                "Only the owner can claim"
            );

            claimedMeth[tokenId] += amount;

            if (!godBulls(tokenId) && breedings(tokenId) == 0) {
                amount += amount / 2;
            }

            if (!prevClaimed[tokenId]) {
                amount += getOldClaimableMeth(tokenId, godBulls(tokenId));
                prevClaimed[tokenId] = true;
            }
        }
    }

    function _breedToken(uint256 tokenId) internal {
        require(
            bapGenesis.ownerOf(tokenId) == msg.sender,
            "Only the owner can breed"
        );

        uint256 currentBreeds = bapGenesis.breedings(tokenId);

        if (breedings(tokenId) == 1) {
            uint256 claimableMeth = _claimMeth(tokenId, 0);
            if (claimableMeth > 0) {
                bapMeth.claim(msg.sender, claimableMeth);
            }
        }

        if (currentBreeds != 0) {
            bapGenesis.updateBullBreedings(tokenId);
        } else {
            require(breedingsLeft[tokenId] != 0, "No more breadings left");
            breedingsLeft[tokenId]--;
        }
    }

    function _burnTeen(uint256 tokenId) internal {
        require(
            bapTeenBulls.ownerOf(tokenId) == msg.sender,
            "Only the owner can burn"
        );
        require(claimedTeenMeth[tokenId] == 0, "Can't burn resurrected teens");

        bapTeenBulls.burnTeenBull(tokenId);
    }

    function random(uint256 seed) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        seed,
                        block.timestamp,
                        gasleft(),
                        tx.origin
                    )
                )
            );
    }

    function _dailyRewards(uint256 _type) internal pure returns (uint256) {
        if (_type == 0) {
            return 10;
        } else if (_type == 1) {
            return 20;
        } else {
            return 5;
        }
    }

    function _refundPeriodAllowed() internal view returns (bool) {
        return
            block.timestamp >= bapGenesis.genesisTimestamp() + 31 days &&
            block.timestamp <= bapGenesis.genesisTimestamp() + 180 days;
    }

    function _verifyHashSignature(bytes32 freshHash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        bytes32 hash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", freshHash)
        );

        bytes32 r;
        bytes32 s;
        uint8 v;

        if (signature.length != 65) {
            return false;
        }
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        address signer = address(0);
        if (v == 27 || v == 28) {
            // solium-disable-next-line arg-overflow
            signer = ecrecover(hash, v, r, s);
        }
        return secret == signer;
    }

    // VIEW FUNCTIONS

    function breedings(uint256 tokenId) public view returns (uint256) {
        uint256 currentBreeds = bapGenesis.breedings(tokenId);

        return currentBreeds + breedingsLeft[tokenId];
    }

    function getClaimableMeth(uint256 tokenId, uint256 _type)
        public
        view
        returns (uint256)
    {
        uint256 claimed = 0;

        if (_type == 2) {
            claimed = claimedTeenMeth[tokenId];
        } else {
            claimed = claimedMeth[tokenId];
        }

        uint256 timeFromCreation = (block.timestamp - startTime) /
            (timeCounter);

        return (timeFromCreation * _dailyRewards(_type)) - claimed;
    }

    function getOldClaimableMeth(uint256 tokenId, bool isGod)
        public
        view
        returns (uint256 methAmount)
    {
        if (prevClaimed[tokenId]) {
            return 0;
        }
        uint256 mintDate = bapOrchestratorV2.bullLastClaim(tokenId);
        uint256 claimed = 0;
        uint256 dailyRewards = isGod ? 20 : 10;

        if (mintDate == 0) {
            if (isGod) {
                mintDate = bapOrchestratorV2.godsMintingDate(tokenId);
            } else {
                mintDate = bapGenesis.mintingDatetime(tokenId);
            }

            claimed = bapOrchestratorV2.totalClaimed(tokenId);
        } else if (!isGod && breedings(tokenId) == 0) {
            dailyRewards = 15;
        }

        if (mintDate > startTime) {
            return 0;
        }

        uint256 timeFromCreation = (startTime - mintDate) / (timeCounter);

        methAmount = dailyRewards * timeFromCreation - claimed;
    }

    function godBulls(uint256 tokenId) public view returns (bool) {
        return tokenId > 10010 || isGod[tokenId];
    }

    function isResurrected(uint256 tokenId) public view returns (bool) {
        return claimedTeenMeth[tokenId] != 0;
    }

    function availableForRefund(uint256 tokenId) public view returns (bool) {
        return
            (_refundPeriodAllowed() || refundFlag) &&
            bapGenesis.breedings(tokenId) == 3 &&
            bapOrchestratorV2.totalClaimed(tokenId) == 0 &&
            claimedMeth[tokenId] == 0 &&
            !prevClaimed[tokenId];
    }

    function onERC721Received(
        address,
        address,
        uint256 tokenId,
        bytes memory
    ) external virtual override returns (bytes4) {
        require(
            msg.sender == address(bapTeenBulls),
            "Only receive from BAP Teens"
        );
        require(isReviving, "Only accept transfers while reviving");
        lastTokenReceived = tokenId;
        return this.onERC721Received.selector;
    }

    // OWNER FUNCTIONS

    function initializeGodBull(uint256[] memory gods, bool godFlag)
        external
        onlyOwner
    {
        for (uint256 i; i < gods.length; i++) {
            isGod[gods[i]] = godFlag;
        }
    }

    function transferExternalOwnership(address _contract, address _newOwner)
        external
        onlyOwner
        noZeroAddress(_newOwner)
    {
        Ownable(_contract).transferOwnership(_newOwner);
    }

    function utilitiesAirdrop(
        address _to,
        uint256 amount,
        uint256 utility
    ) external onlyOwner noZeroAddress(_to) {
        bapUtilities.airdrop(_to, amount, utility);
    }

    function teenAirdrop(address _to, uint256 amount)
        external
        onlyOwner
        noZeroAddress(_to)
    {
        bapTeenBulls.airdrop(_to, amount);
    }

    function setGenesisContract(address _newAddress)
        external
        onlyOwner
        noZeroAddress(_newAddress)
    {
        bapGenesis = BAPGenesisInterface(_newAddress);
    }

    function setMethaneContract(address _newAddress)
        external
        onlyOwner
        noZeroAddress(_newAddress)
    {
        bapMeth = BAPMethaneInterface(_newAddress);
    }

    function setUtilitiesContract(address _newAddress)
        external
        onlyOwner
        noZeroAddress(_newAddress)
    {
        bapUtilities = BAPUtilitiesInterface(_newAddress);
    }

    function setTeenBullsContract(address _newAddress)
        external
        onlyOwner
        noZeroAddress(_newAddress)
    {
        bapTeenBulls = BAPTeenBullsInterface(_newAddress);
    }

    function setTreasuryWallet(address _newTreasuryWallet)
        external
        onlyOwner
        noZeroAddress(_newTreasuryWallet)
    {
        treasuryWallet = _newTreasuryWallet;
    }

    function setWhitelistedAddress(address _secret)
        external
        onlyOwner
        noZeroAddress(_secret)
    {
        secret = _secret;
    }

    function setTimeCounter(uint256 _timeCounter) external onlyOwner {
        timeCounter = _timeCounter;
    }

    function setPowerCooldown(uint256 _powerCooldown) external onlyOwner {
        powerCooldown = _powerCooldown;
    }

    function setRefundFlag(bool _refundFlag) external onlyOwner {
        refundFlag = _refundFlag;
    }

    function setClaimFlag(bool _claimFlag) external onlyOwner {
        claimFlag = _claimFlag;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface BAPUtilitiesInterface {
    function burn(uint256, uint256) external;

    function purchaseIncubator() external;

    function purchaseMergerOrb() external;

    function transferOwnership(address) external;

    function airdrop(
        address,
        uint256,
        uint256
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface BAPTeenBullsInterface {
    function generateTeenBull() external;

    function generateMergerOrb() external;

    function ownerOf(uint256) external view returns (address);

    function burnTeenBull(uint256) external;

    function airdrop(address, uint256) external;

    function safeTransferFrom(
        address,
        address,
        uint256
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface BAPOrchestratorInterfaceV2 {
    function prevClaimed(uint256) external returns (bool);

    function totalClaimed(uint256) external view returns (uint256);

    function bullLastClaim(uint256) external view returns (uint256);

    function godsMintingDate(uint256) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface BAPMethaneInterface {
    function claim(address, uint256) external;

    function pay(uint256, uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface BAPGenesisInterface {
    function minted() external view returns (uint256);

    function mintingDatetime(uint256) external view returns (uint256);

    function updateBullBreedings(uint256) external;

    function ownerOf(uint256) external view returns (address);

    function breedings(uint256) external view returns (uint256);

    function maxBreedings() external view returns (uint256);

    function generateGodBull() external;

    function refund(address, uint256) external payable;

    function safeTransferFrom(
        address,
        address,
        uint256
    ) external;

    function genesisTimestamp() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.0.0

pragma solidity ^0.8.4;

/**
 * @dev ERC721 token receiver interface.
 */
interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
/**
 *Submitted for verification at Etherscan.io on 2022-05-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/**
  * @title Insurance Purchaser
  * @author René Hochmuth
  */

interface IERC20 {

    function totalSupply()
        external
        view
        returns (uint256);

    function balanceOf(
        address _account
    )
        external
        view
        returns (uint256);

    function transfer(
        address _recipient,
        uint256 _amount
    )
        external
        returns (bool);

    function approve(
        address _spender,
        uint256 _amount
    )
        external
        returns (bool);

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    )
        external
        returns (bool);

    function decimals()
        external
        view
        returns (uint8);
}

interface ISeeder{

    function getBatch()
        external
        view
        returns(uint256);

    function getNextAvailableBatch()
        external
        view
        returns(uint256);

    function getSeedSafe(
        address origin,
        uint256 identifier
    )
        external
        view
        returns(uint256);
}

interface IRevealContract{

    function enhancementCost(
        uint256
    )
        external
        view
        returns (
            uint256,
            bool
        );

    function getEnhancementRequest(
        uint256 tokenId
    )
        external
        view
        returns (
            uint256 id,
            address requester
        );

    function reveal(
        uint256[] calldata tokenIds
    )
        external;
}

interface IMainGame {

    function getUserFighters(
        address user
    )
        external
        view
        returns (
            uint256[] memory
        );

    function getUserHero(
        address user
    )
        external
        view
        returns (uint256);

    function equip(
        uint8 item,
        uint256 id,
        uint8 slot
    )
        external;

    function unequip(
        uint8 item,
        uint8 slot
    )
        external;

    function enhance(
        uint8 item,
        uint8 slot,
        uint256 burnTokenId
    )
        external;

}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

contract RaidPartyInsuranceDeclaration {

    IERC20 public immutable confettiToken;
    IERC721 public immutable hero;
    IERC721 public immutable fighter;

    IRevealContract public immutable revealFighterContract;
    IRevealContract public immutable revealHeroContract;
    IMainGame public immutable mainGame;
    ISeeder public immutable seeder;

    address public immutable CONFETTI_TOKEN_ADDRESS;
    address public immutable REVEAL_FIGHTER_CONTRACT_ADDRESS;
    address public immutable REVEAL_HERO_CONTRACT_ADDRESS;
    address public immutable MAIN_GAME_CONTRACT_ADDRESS;
    address public immutable SEEDER_CONTRACT_ADDRESS;
    address public immutable HERO_CONTRACT_ADDRESS;
    address public immutable FIGHTER_CONTRACT_ADDRESS;

    address public masterAddress;
    uint256 public confettiReserves;

    uint256 constant PRECISION = 10 ** 18;
    address constant ZERO_ADDRESS = address(0x0);

    uint256 public immutable MAX_FIGHTER_ENHANCECOST;
    uint256 public immutable MAX_HERO_ENHANCECOST;
    uint256 public immutable HERO_ENHANCE_RESERVE_NEEDED_CUTOFF;

    uint256[] public heroReserves;
    uint256[] public fighterReserves;

    bool public registerAllowed = true;

    mapping(uint256 => uint256) public batchNumberRegisterHero;
    mapping(uint256 => uint256) public batchNumberRegisterFighter;

    mapping(uint256 => uint256) public heroReservesPerBatch;
    mapping(uint256 => uint256) public fighterReservesPerBatch;

    mapping(uint256 => uint256) public lastEnhanceCostHeroByID;
    mapping(uint256 => uint256) public lastEnhanceCostFighterByID;

    mapping(uint256 => uint256) public insuranceCostHeroByEnhanceCost;
    mapping(uint256 => uint256) public insuranceCostFighterByEnhanceCost;

    mapping(uint256 => mapping(uint256 => bool)) public tokenIDClaimedInBatchHero;
    mapping(uint256 => mapping(uint256 => bool)) public tokenIDClaimedInBatchFighter;

    mapping(uint256 => uint256) public confettiReservesPerBatch;

    modifier onlyMaster() {
        require(
            masterAddress == msg.sender,
            "RaidPartyInsurance: ACCESS_DENIED"
        );
        _;
     }

    modifier registerAllowedCheck() {
        require(
            registerAllowed == true,
            "RaidPartyInsurance: REGISTER_NOT_ALLOWED"
        );
        _;
    }

    constructor(
        address _CONFETTI_TOKEN_ADDRESS,
        address _REVEAL_FIGHTER_CONTRACT_ADDRESS,
        address _MAIN_GAME_CONTRACT_ADDRESS,
        address _SEEDER_CONTRACT_ADDRESS,
        address _HERO_CONTRACT_ADDRESS,
        address _FIGHTER_CONTRACT_ADDRESS,
        address _REVEAL_HERO_CONTRACT_ADDRESS
    ) {
        CONFETTI_TOKEN_ADDRESS = _CONFETTI_TOKEN_ADDRESS;
        REVEAL_FIGHTER_CONTRACT_ADDRESS = _REVEAL_FIGHTER_CONTRACT_ADDRESS;
        MAIN_GAME_CONTRACT_ADDRESS = _MAIN_GAME_CONTRACT_ADDRESS;
        SEEDER_CONTRACT_ADDRESS = _SEEDER_CONTRACT_ADDRESS;
        HERO_CONTRACT_ADDRESS = _HERO_CONTRACT_ADDRESS;
        FIGHTER_CONTRACT_ADDRESS = _FIGHTER_CONTRACT_ADDRESS;
        REVEAL_HERO_CONTRACT_ADDRESS = _REVEAL_HERO_CONTRACT_ADDRESS;

        confettiToken = IERC20(
            CONFETTI_TOKEN_ADDRESS
        );

        revealFighterContract = IRevealContract(
            REVEAL_FIGHTER_CONTRACT_ADDRESS
        );

        revealHeroContract = IRevealContract(
            REVEAL_HERO_CONTRACT_ADDRESS
        );

        mainGame = IMainGame(
            MAIN_GAME_CONTRACT_ADDRESS
        );

        seeder = ISeeder(
            SEEDER_CONTRACT_ADDRESS
        );

        hero = IERC721(
            HERO_CONTRACT_ADDRESS
        );

        fighter = IERC721(
            FIGHTER_CONTRACT_ADDRESS
        );

        MAX_FIGHTER_ENHANCECOST = 350 * PRECISION;
        HERO_ENHANCE_RESERVE_NEEDED_CUTOFF = 1250 * PRECISION;
        MAX_HERO_ENHANCECOST = 2250 * PRECISION;

        insuranceCostFighterByEnhanceCost[25 * PRECISION] = 25 * PRECISION;
        insuranceCostFighterByEnhanceCost[35 * PRECISION] = 34 * PRECISION;
        insuranceCostFighterByEnhanceCost[50 * PRECISION] = 45 * PRECISION;
        insuranceCostFighterByEnhanceCost[75 * PRECISION] = 61 * PRECISION;
        insuranceCostFighterByEnhanceCost[100 * PRECISION] = 80 * PRECISION;
        insuranceCostFighterByEnhanceCost[125 * PRECISION] = 101 * PRECISION;
        insuranceCostFighterByEnhanceCost[150 * PRECISION] = 125 * PRECISION;
        insuranceCostFighterByEnhanceCost[300 * PRECISION] = 220 * PRECISION;
        insuranceCostFighterByEnhanceCost[350 * PRECISION] = 270 * PRECISION;

        insuranceCostHeroByEnhanceCost[250 * PRECISION] = 50 * PRECISION;
        insuranceCostHeroByEnhanceCost[500 * PRECISION] = 125 * PRECISION;
        insuranceCostHeroByEnhanceCost[750 * PRECISION] = 225 * PRECISION;
        insuranceCostHeroByEnhanceCost[1000 * PRECISION] = 350 * PRECISION;
        insuranceCostHeroByEnhanceCost[1250 * PRECISION] = 1100 * PRECISION;
        insuranceCostHeroByEnhanceCost[1500 * PRECISION] = 1350 * PRECISION;
        insuranceCostHeroByEnhanceCost[1750 * PRECISION] = 1625 * PRECISION;
        insuranceCostHeroByEnhanceCost[2000 * PRECISION] = 1925 * PRECISION;
        insuranceCostHeroByEnhanceCost[2250 * PRECISION] = 2250 * PRECISION;
    }
}

contract RaidPartyInsuranceEvents {

    event insurancePurchased(
        address user,
        bool isFighter,
        uint256 enhanceCost,
        uint256 batch,
        uint256 cost
    );

    event insuranceClaimed(
        address user,
        bool isFighter,
        bool nftCompensation,
        uint256 tokensClaimed
    );

    event PassedBatchCheck(
        uint256[] tokenIDs
    );
}

abstract contract RaidPartyInsuranceHelper is
    RaidPartyInsuranceDeclaration,
    RaidPartyInsuranceEvents
{
    function _buyInsuranceFighter(
        uint256 _tokenID,
        uint256 _fighterPos
    )
        internal
    {
        uint256[] memory tokenIDarray = new uint256[](1);
        tokenIDarray[0] = _tokenID;

        (
            uint256 batch,
            uint256 nextBatch
        ) = _getBatches();

        require(
            _checkPendingRevealFighter(_tokenID) == true,
            "RaidPartyInsuranceHelper: NO_PENDING_REVEAL"
        );

        _sameBatchCheck(
            REVEAL_FIGHTER_CONTRACT_ADDRESS,
            tokenIDarray
        );

        _checkIfInMainGameFighter(
            _tokenID,
            _fighterPos,
            msg.sender
        );

        require(
            batchNumberRegisterFighter[_tokenID] < batch,
            "RaidPartyInsuranceHelper: ALREADY_REGISTERED"
        );

        batchNumberRegisterFighter[_tokenID] = batch;

        uint256 enhanceCost = _determineEnhanceCost(
            REVEAL_FIGHTER_CONTRACT_ADDRESS,
            _tokenID
        );

        require(
            enhanceCost <= MAX_FIGHTER_ENHANCECOST,
            "RaidPartyInsuranceHelper: LEVEL_TOO_HIGH"
        );

        lastEnhanceCostFighterByID[_tokenID] = enhanceCost;

        fighterReservesPerBatch[nextBatch] += 1;
        confettiReservesPerBatch[nextBatch] += enhanceCost;

        uint256 insuranceCost = insuranceCostFighterByEnhanceCost[enhanceCost];

        confettiReserves += insuranceCost;

        _determineConfettiCoverageTotal();
        _determineReserveCoverageTotalFighter();

        confettiToken.transferFrom(
            msg.sender,
            address(this),
            insuranceCost
        );

        emit insurancePurchased(
            msg.sender,
            true,
            enhanceCost,
            batch,
            insuranceCost
        );
    }

    function _buyInsuranceHero(
        uint256 _tokenID
    )
        internal
    {
        (
            uint256 batch,
            uint256 nextBatch
        ) = _getBatches();

        uint256[] memory tokenIDarray = new uint256[](1);
        tokenIDarray[0] = _tokenID;

        require(
            _checkPendingRevealHero(_tokenID) == true,
            "RaidPartyInsuranceHelper: NO_PENDING_REVEAL"
        );

        _sameBatchCheck(
            REVEAL_HERO_CONTRACT_ADDRESS,
            tokenIDarray
        );

        _checkIfInMainGameHero(
            _tokenID,
            msg.sender
        );

        _checkDblRegisterHero(
            batch,
            _tokenID
        );

        batchNumberRegisterHero[_tokenID] = batch;

        uint256 enhanceCost = _determineEnhanceCost(
            REVEAL_HERO_CONTRACT_ADDRESS,
            _tokenID
        );

        require(
            enhanceCost <= MAX_HERO_ENHANCECOST,
            "RaidPartyInsuranceHelper: LEVEL_TOO_HIGH"
        );

        lastEnhanceCostHeroByID[_tokenID] = enhanceCost;

        confettiReservesPerBatch[nextBatch] =
        confettiReservesPerBatch[nextBatch] + enhanceCost;

        uint256 insuranceCost = insuranceCostHeroByEnhanceCost[enhanceCost];

        confettiReserves =
        confettiReserves + insuranceCost;

        _determineConfettiCoverageTotal();

        if (enhanceCost >= HERO_ENHANCE_RESERVE_NEEDED_CUTOFF) {
            heroReservesPerBatch[nextBatch] += 1;
            _determineReserveCoverageTotalHero();
        }

        confettiToken.transferFrom(
            msg.sender,
            address(this),
            insuranceCost
        );

        emit insurancePurchased(
            msg.sender,
            false,
            enhanceCost,
            batch,
            insuranceCost
        );
    }

    function _addFighterReserve(
        uint256 _tokenID
    )
        internal
    {
        fighterReserves.push(
            _tokenID
        );

        fighter.safeTransferFrom(
            msg.sender,
            address(this),
            _tokenID
        );
    }

    function _addHeroReserve(
        uint256 _tokenID
    )
        internal
    {
        heroReserves.push(
            _tokenID
        );

        hero.safeTransferFrom(
            msg.sender,
            address(this),
            _tokenID
        );
    }

    function _insuranceClaimHero(
        uint256 _tokenID
    )
        internal
    {
        uint256 batch = _getBatch();

        uint256[] memory tokenIDarray = new uint256[](1);
        tokenIDarray[0] = _tokenID;

        require(
            batchNumberRegisterHero[_tokenID] + 1 == batch,
            "RaidPartyInsuranceHelper: WRONG_BATCH"
        );

        _checkIfInMainGameHero(
            _tokenID,
            msg.sender
        );

        require(
            tokenIDClaimedInBatchHero[_tokenID][batch] == false,
            "RaidPartyInsuranceHelper: ALREADY_CLAIMED"
        );

        if (_checkPendingRevealHero(_tokenID) == true) {

            revealHeroContract.reveal(
                tokenIDarray
            );
        }

        uint256 enhanceCost = _determineEnhanceCost(
            REVEAL_HERO_CONTRACT_ADDRESS,
            _tokenID
        );

        uint256 previousEnhanceCost = lastEnhanceCostHeroByID[_tokenID];

        if (enhanceCost > previousEnhanceCost) return;

        tokenIDClaimedInBatchHero[_tokenID][batch] = true;
        confettiReservesPerBatch[batch] -= previousEnhanceCost;
        confettiReserves -= previousEnhanceCost;

        bool nftCompensation = previousEnhanceCost >= HERO_ENHANCE_RESERVE_NEEDED_CUTOFF;

        if (nftCompensation == true) {
            heroReservesPerBatch[batch] -= 1;
            hero.safeTransferFrom(
                address(this),
                msg.sender,
                _adjustHeroReserveArray()
            );
        }

        confettiToken.transfer(
            msg.sender,
            previousEnhanceCost
        );

        emit insuranceClaimed(
            msg.sender,
            false,
            nftCompensation,
            previousEnhanceCost
        );
    }

    function _insuranceClaimFighter(
        uint256 _tokenID,
        uint256 _fighterPos
    )
        internal
    {
        uint256 batch = _getBatch();

        uint256[] memory tokenIDarray = new uint256[](1);
        tokenIDarray[0] = _tokenID;

        require(
            batchNumberRegisterFighter[_tokenID] + 1 == batch,
            "RaidPartyInsuranceHelper: WRONG_BATCH"
        );

        _checkIfInMainGameFighter(
            _tokenID,
            _fighterPos,
            msg.sender
        );

        require(
            tokenIDClaimedInBatchFighter[_tokenID][batch] == false,
            "RaidPartyInsuranceHelper: ALREADY_CLAIMED"
        );

        if (_checkPendingRevealFighter(_tokenID) == true) {
            revealFighterContract.reveal(tokenIDarray);
        }

        uint256 enhanceCost = _determineEnhanceCost(
            REVEAL_FIGHTER_CONTRACT_ADDRESS,
            _tokenID
        );

        uint256 previousEnhanceCost = lastEnhanceCostFighterByID[_tokenID];

        if (enhanceCost > previousEnhanceCost) return;

        tokenIDClaimedInBatchFighter[_tokenID][batch] = true;
        confettiReservesPerBatch[batch] -= previousEnhanceCost;
        fighterReservesPerBatch[batch] -= 1;
        confettiReserves -= previousEnhanceCost;

        confettiToken.transfer(
            msg.sender,
            previousEnhanceCost
        );

        fighter.safeTransferFrom(
            address(this),
            msg.sender,
            _adjustFighterReserveArray()
        );

        emit insuranceClaimed(
            msg.sender,
            true,
            true,
            previousEnhanceCost
        );
    }

    function _withdrawHeroAdmin()
        internal
    {
        uint256 lastTokenID = _adjustHeroReserveArray();
        _determineReserveCoverageTotalHero();

        hero.safeTransferFrom(
            address(this),
            msg.sender,
            lastTokenID
        );
    }

    function _withdrawFighterAdmin()
        internal
    {
        uint256 lastTokenID = _adjustFighterReserveArray();
        _determineReserveCoverageTotalFighter();

        fighter.safeTransferFrom(
            address(this),
            msg.sender,
            lastTokenID
        );
    }

    function _sameBatchCheck(
        address _toCall,
        uint256[] memory _tokenIDs
    )
        internal
    {
        try IRevealContract(_toCall).reveal(
            _tokenIDs
        )
        {
            revert(
                "RaidPartyInsuranceHelper: NOT_SAME_BATCH"
            );
        }
        catch
        {
            emit PassedBatchCheck(
                _tokenIDs
            );
        }
    }

    function _checkDblRegisterHero(
        uint256 _batch,
        uint256 _tokenID
    )
        internal
        view
    {
        require(
            batchNumberRegisterHero[_tokenID] < _batch,
            "RaidPartyInsuranceHelper: ALREADY_REGISTERED"
        );
    }

    function _getBatch()
        internal
        view
        returns (uint256)
    {
        return seeder.getBatch();
    }

    function _getBatches()
        internal
        view
        returns (
            uint256 batch,
            uint256 nextBatch
        )
    {
        batch = _getBatch();
        nextBatch = batch + 1;
    }

    function _checkIfInMainGameFighter(
        uint256 _tokenID,
        uint256 _fighterPos,
        address _user
    )
        internal
        view
    {
        require(
            mainGame.getUserFighters(_user)[_fighterPos] == _tokenID,
            "RaidPartyInsuranceHelper: WRONG_TOKEN_ID"
        );
    }

    function _checkIfInMainGameHero(
        uint256 _tokenID,
        address _user
    )
        internal
        view
    {
        require(
            mainGame.getUserHero(_user) == _tokenID,
            "RaidPartyInsuranceHelper: WRONG_TOKEN_ID"
        );
    }

    function _determineEnhanceCost(
        address _toCall,
        uint256 _tokenID
    )
        internal
        view
        returns (uint256)
    {
        (
            uint256 enhanceCost,
        ) = IRevealContract(_toCall).enhancementCost(
            _tokenID
        );

        return enhanceCost;
    }

    function _determineReserveCoverageFighter(
        uint256 _fighterCount
    )
        internal
        view
        returns (bool)
    {
        return fighterReserves.length >= _fighterCount;
    }

    function _determineReserveCoverageHero(
        uint256 _heroCount
    )
        internal
        view
        returns (bool)
    {
        return heroReserves.length >= _heroCount;
    }

    function _determineReserveCoverageTotalFighter()
        internal
        view
        returns (bool)
    {
        uint256 batch = _getBatch();
        uint256 nextBatch = batch + 1;

        uint256 requiredTotal =
            fighterReservesPerBatch[batch] +
            fighterReservesPerBatch[nextBatch];

        require(
            _determineReserveCoverageFighter(requiredTotal) == true,
            "RaidPartyInsuranceHelper: VIOLATES_COVERAGE_FIGHTER"
        );

        return true;
    }

    function _determineReserveCoverageTotalHero()
        internal
        view
        returns (bool)
    {
        (
            uint256 batch,
            uint256 nextBatch
        ) = _getBatches();

        uint256 requiredTotal =
            heroReservesPerBatch[batch] +
            heroReservesPerBatch[nextBatch];

        require(
            _determineReserveCoverageHero(requiredTotal) == true,
            "RaidPartyInsuranceHelper: VIOLATES_COVERAGE_HERO"
        );

        return true;
    }

    function _determineConfettiCoverage(
        uint256 _confettiAmount
    )
        internal
        view
        returns (bool)
    {
        return confettiReserves >= _confettiAmount;
    }

    function _determineConfettiCoverageTotal()
        internal
        view
        returns (bool)
    {
        (
            uint256 batch,
            uint256 nextBatch
        ) = _getBatches();

        uint256 requiredTotal =
            confettiReservesPerBatch[batch] +
            confettiReservesPerBatch[nextBatch];

        require(
            _determineConfettiCoverage(requiredTotal) == true,
            "RaidPartyInsuranceHelper: VIOLATES_COVERAGE_CONFETII"
        );

        return true;
    }

    function _adjustHeroReserveArray()
        internal
        returns (uint256)
    {
        uint256 lastIndex = heroReserves.length - 1;
        uint256 lastTokenID = heroReserves[lastIndex];

        heroReserves.pop();
        return lastTokenID;
    }

    function _adjustFighterReserveArray()
        internal
        returns (uint256)
    {
        uint256 lastIndex = fighterReserves.length - 1;
        uint256 lastTokenID = fighterReserves[lastIndex];

        fighterReserves.pop();
        return lastTokenID;
    }

    function _checkPendingRevealFighter(
        uint256 _tokenID
    )
        internal
        view
        returns (bool)
    {
        (
            ,
            address enhancer
        ) = revealFighterContract.getEnhancementRequest(
            _tokenID
        );

        return enhancer > ZERO_ADDRESS;
    }

    function _checkPendingRevealHero(
        uint256 _tokenID
    )
        internal
        view
        returns (bool)
    {
        (
            ,
            address enhancer
        ) = revealHeroContract.getEnhancementRequest(
            _tokenID
        );

        return enhancer > ZERO_ADDRESS;
    }
}

contract RaidPartyInsurance is RaidPartyInsuranceHelper {

    constructor(
        address _CONFETTI_TOKEN_ADDRESS,
        address _REVEAL_FIGHTER_CONTRACT_ADDRESS,
        address _MAIN_GAME_CONTRACT_ADDRESS,
        address _SEEDER_CONTRACT_ADDRESS,
        address _HERO_CONTRACT_ADDRESS,
        address _FIGHTER_CONTRACT_ADDRESS,
        address _REVEAL_HERO_CONTRACT_ADDRESS
    )
        RaidPartyInsuranceDeclaration(
            _CONFETTI_TOKEN_ADDRESS,
            _REVEAL_FIGHTER_CONTRACT_ADDRESS,
            _MAIN_GAME_CONTRACT_ADDRESS,
            _SEEDER_CONTRACT_ADDRESS,
            _HERO_CONTRACT_ADDRESS,
            _FIGHTER_CONTRACT_ADDRESS,
            _REVEAL_HERO_CONTRACT_ADDRESS
        )
    {
        masterAddress = msg.sender;
    }

    function buyInsuranceFighter(
        uint256 _tokenID,
        uint256 _fighterPos
    )
        registerAllowedCheck
        external
    {
        _buyInsuranceFighter(
            _tokenID,
            _fighterPos
        );
    }

    function buyInsuranceHero(
        uint256 _tokenID
    )
        registerAllowedCheck
        external
    {
        _buyInsuranceHero(
            _tokenID
        );
    }

    function buyInsuranceFighterBulk(
        uint256[] calldata _tokenIDs,
        uint256[] calldata _fighterPositions
    )
        external
    {
        for (uint i = 0; i < _tokenIDs.length; i++) {
            _buyInsuranceFighter(
                _tokenIDs[i],
                _fighterPositions[i]
            );
        }
    }

    function insuranceClaimHero(
        uint256 _tokenID
    )
        external
    {
        _insuranceClaimHero(
            _tokenID
        );
    }

    function insuranceClaimFighter(
        uint256 _tokenID,
        uint256 _fighterPos
    )
        external
    {
        _insuranceClaimFighter(
            _tokenID,
            _fighterPos
        );
    }

    function InsuranceClaimFighterBulk(
        uint256[] calldata _tokenIDs,
        uint256[] calldata _fighterPositions
    )
        external
    {
        for (uint i = 0; i < _tokenIDs.length; i++) {
            _insuranceClaimFighter(
                _tokenIDs[i],
                _fighterPositions[i]
            );
        }
    }

    function addConfettiReserve(
        uint256 _amount
    )
        external
    {
        confettiReserves =
        confettiReserves + _amount;

        confettiToken.transferFrom(
            msg.sender,
            address(this),
            _amount
        );
    }

    function addFighterReserve(
        uint256 _tokenID
    )
        external
    {
        _addFighterReserve(
            _tokenID
        );
    }

    function addHeroReserve(
        uint256 _tokenID
    )
        external
    {
        _addHeroReserve(
            _tokenID
        );
    }

    function addHeroReserveBulk(
        uint256[] calldata _tokenIDs
    )
        external
    {
        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            _addHeroReserve(
                _tokenIDs[i]
            );
        }
    }

    function addFighterReserveBulk(
        uint256[] calldata _tokenIDs
    )
        external
    {
        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            _addFighterReserve(
                _tokenIDs[i]
            );
        }
    }

    function withdrawConfettiAdmin(
        uint256 _amount
    )
        onlyMaster
        external
    {
        confettiReserves -= _amount;
        _determineConfettiCoverageTotal();

        confettiToken.transfer(
            msg.sender,
            _amount
        );
    }

    function withdrawHeroAdmin()
        onlyMaster
        external
    {
        _withdrawHeroAdmin();
    }

    function withdrawHeroAdminBulk(
        uint256 _heroes
    )
        onlyMaster
        external
    {
        for (uint256 i = 0; i < _heroes; i++) {
            _withdrawHeroAdmin();
        }
    }

    function withdrawFighterAdmin()
        onlyMaster
        external
    {
        _withdrawFighterAdmin();
    }

    function withdrawFighterAdminBulk(
        uint256 _fighters
    )
        onlyMaster
        external
    {
        for (uint256 i = 0; i < _fighters; i++) {
            _withdrawFighterAdmin();
        }
    }

    function secondsUntilNextBatch()
        external
        view
        returns (uint256)
    {
        (
            uint256 futureStamp,
            uint256 currentStamp
        ) = (
            seeder.getNextAvailableBatch(),
            block.timestamp
        );

        return futureStamp > currentStamp
            ? futureStamp
            : 0;
    }

    function potentialRegisterIDsUserHero(
        address _user
    )
        external
        view
        returns (uint256)
    {
        uint256 currentHeroID = mainGame.getUserHero(
            _user
        );

        (
            uint256 currentEnhanceCost,
            uint256 batch
        ) = (
            _determineEnhanceCost(
                REVEAL_HERO_CONTRACT_ADDRESS,
                currentHeroID
            ),
            _getBatch()
        );

        (uint256 currentRequestID,) = revealHeroContract.getEnhancementRequest(
            currentHeroID
        );

        try seeder.getSeedSafe(
            REVEAL_HERO_CONTRACT_ADDRESS,
            currentRequestID
        ) {}
        catch
        {
            if (_conditionCheckHero(batch, currentEnhanceCost, currentHeroID)) {
                return currentHeroID;
            }
        }

        return 0;
    }

    function _conditionCheckHero(
        uint256 _batch,
        uint256 _currentEnhanceCost,
        uint256 _currentHeroID
    )
        internal
        view
        returns (bool)
    {
        return _currentEnhanceCost < MAX_HERO_ENHANCECOST
            && _checkPendingRevealHero(_currentHeroID)
            && batchNumberRegisterHero[_currentHeroID] < _batch;
    }

    function getBatch()
        external
        view
        returns (uint256)
    {
        return _getBatch();
    }

    function activeRemainingFighterReserves()
        external
        view
        returns (uint256)
    {
        uint256 batch = _getBatch();

        return fighterReserves.length
            - fighterReservesPerBatch[batch]
            - fighterReservesPerBatch[batch + 1];
    }

    function activeRemainingHeroReserves()
        external
        view
        returns (uint256)
    {
        uint256 batch = _getBatch();

        return heroReserves.length
            - heroReservesPerBatch[batch]
            - heroReservesPerBatch[batch + 1];
    }

    function potentialRegisterIDsUserFighter(
        address _user
    )
        external
        view
        returns (uint256[] memory)
    {
        (
            uint256 length,
            uint256 currentFighterID,
            uint256 currentEnhanceCost,
            uint256 batch,
            uint256 currentRequestID,
            uint256 k
        ) = (
            mainGame.getUserFighters(_user).length,
            0,
            0,
            _getBatch(),
            0,
            0
        );

        uint256[] memory loadArray = new uint256[](
            length
        );

        for (uint256 i = 0; i < length; i++) {

            currentFighterID = mainGame.getUserFighters(_user)[i];

            currentEnhanceCost = _determineEnhanceCost(
                REVEAL_FIGHTER_CONTRACT_ADDRESS,
                currentFighterID
            );

            (
                currentRequestID,
            ) = revealFighterContract.getEnhancementRequest(
                currentFighterID
            );

            try seeder.getSeedSafe(
                REVEAL_FIGHTER_CONTRACT_ADDRESS,
                currentRequestID
            ) {}
            catch
            {
                if (_conditionCheckFighter(batch, currentFighterID, currentEnhanceCost)) {
                    loadArray[k] = currentFighterID;
                    k += 1;
                }
            }
        }

        uint256[] memory returnArray = new uint256[](k);

        for (uint256 index = 0; index < k; index++) {
            returnArray[index] = loadArray[index];
        }

        return returnArray;
    }

    function _conditionCheckFighter(
        uint256 _batch,
        uint256 _currentFighterID,
        uint256 _currentEnhanceCost
    )
        internal
        view
        returns (bool)
    {
        return _currentEnhanceCost < MAX_FIGHTER_ENHANCECOST
            && _checkPendingRevealFighter(_currentFighterID)
            && batchNumberRegisterFighter[_currentFighterID] < _batch;
    }

    function changeMaster(
        address _newMaster
    )
        onlyMaster
        external
    {
        masterAddress = _newMaster;
    }

    function enableRegister()
        onlyMaster
        external
    {
        registerAllowed = true;
    }

    function disableRegister()
        onlyMaster
        external
    {
        registerAllowed = false;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    )
        public
        pure
        returns (bytes4)
    {
        return this.onERC721Received.selector;
    }
}
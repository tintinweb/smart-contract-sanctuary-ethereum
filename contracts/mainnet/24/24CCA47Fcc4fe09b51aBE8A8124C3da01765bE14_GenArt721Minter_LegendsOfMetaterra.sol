// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

import "../../interfaces/0.8.x/IGenArt721CoreV2_PBAB.sol";
import "../../interfaces/0.8.x/IBonusContract.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

pragma solidity 0.8.9;

/**
 * @title Powered by Art Blocks minter contract that allows tokens to be
 * minted with ETH or any ERC-20 token.
 * @author Art Blocks Inc.
 */
contract GenArt721Minter_LegendsOfMetaterra is ReentrancyGuard {
    /// PBAB core contract this minter may interact with.
    IGenArt721CoreV2_PBAB public genArtCoreContract;

    uint256 constant ONE_MILLION = 1_000_000;

    address payable public ownerAddress;
    uint256 public ownerPercentage;

    mapping(uint256 => bool) public projectIdToBonus;
    mapping(uint256 => address) public projectIdToBonusContractAddress;
    mapping(uint256 => bool) public contractFilterProject;
    mapping(address => mapping(uint256 => uint256)) public projectMintCounter;
    mapping(uint256 => uint256) public projectMintLimit;
    mapping(uint256 => bool) public projectMaxHasBeenInvoked;
    mapping(uint256 => uint256) public projectMaxInvocations;

    /**
     * @notice Initializes contract to be a Minter for PBAB core contract at
     * address `_genArt721Address`.
     */
    constructor(address _genArt721Address) ReentrancyGuard() {
        genArtCoreContract = IGenArt721CoreV2_PBAB(_genArt721Address);
    }

    /**
     * @notice Gets your balance of the ERC-20 token currently set
     * as the payment currency for project `_projectId`.
     * @param _projectId Project ID to be queried.
     * @return balance Balance of ERC-20
     */
    function getYourBalanceOfProjectERC20(uint256 _projectId)
        public
        view
        returns (uint256)
    {
        uint256 balance = IERC20(
            genArtCoreContract.projectIdToCurrencyAddress(_projectId)
        ).balanceOf(msg.sender);
        return balance;
    }

    /**
     * @notice Gets your allowance for this minter of the ERC-20
     * token currently set as the payment currency for project
     * `_projectId`.
     * @param _projectId Project ID to be queried.
     * @return remaining Remaining allowance of ERC-20
     */
    function checkYourAllowanceOfProjectERC20(uint256 _projectId)
        public
        view
        returns (uint256)
    {
        uint256 remaining = IERC20(
            genArtCoreContract.projectIdToCurrencyAddress(_projectId)
        ).allowance(msg.sender, address(this));
        return remaining;
    }

    /**
     * @notice Sets the mint limit of a single purchaser for project
     * `_projectId` to `_limit`.
     * @param _projectId Project ID to set the mint limit for.
     * @param _limit Number of times a given address may mint the project's
     * tokens.
     */
    function setProjectMintLimit(uint256 _projectId, uint8 _limit) public {
        require(
            genArtCoreContract.isWhitelisted(msg.sender),
            "can only be set by admin"
        );
        projectMintLimit[_projectId] = _limit;
    }

    /**
     * @notice Sets the maximum invocations of project `_projectId` based
     * on the value currently defined in the core contract.
     * @param _projectId Project ID to set the maximum invocations for.
     * @dev also checks and may refresh projectMaxHasBeenInvoked for project
     */
    function setProjectMaxInvocations(uint256 _projectId) public {
        require(
            genArtCoreContract.isWhitelisted(msg.sender),
            "can only be set by admin"
        );
        uint256 maxInvocations;
        uint256 invocations;
        (, , invocations, maxInvocations, , , , , ) = genArtCoreContract
            .projectTokenInfo(_projectId);
        projectMaxInvocations[_projectId] = maxInvocations;
        if (invocations < maxInvocations) {
            projectMaxHasBeenInvoked[_projectId] = false;
        }
    }

    /**
     * @notice Sets the owner address to `_ownerAddress`.
     * @param _ownerAddress New owner address.
     */
    function setOwnerAddress(address payable _ownerAddress) public {
        require(
            genArtCoreContract.isWhitelisted(msg.sender),
            "can only be set by admin"
        );
        ownerAddress = _ownerAddress;
    }

    /**
     * @notice Sets the owner mint revenue to `_ownerPercentage` percent.
     * @param _ownerPercentage New owner percentage.
     */
    function setOwnerPercentage(uint256 _ownerPercentage) public {
        require(
            genArtCoreContract.isWhitelisted(msg.sender),
            "can only be set by admin"
        );
        ownerPercentage = _ownerPercentage;
    }

    /**
     * @notice Toggles if contracts are allowed to mint tokens for
     * project `_projectId`.
     * @param _projectId Project ID to be toggled.
     */
    function toggleContractFilter(uint256 _projectId) public {
        require(
            genArtCoreContract.isWhitelisted(msg.sender),
            "can only be set by admin"
        );
        contractFilterProject[_projectId] = !contractFilterProject[_projectId];
    }

    /**
     * @notice Toggles if bonus contract for project `_projectId`.
     * @param _projectId Project ID to be toggled.
     */
    function artistToggleBonus(uint256 _projectId) public {
        require(
            msg.sender ==
                genArtCoreContract.projectIdToArtistAddress(_projectId),
            "can only be set by artist"
        );
        projectIdToBonus[_projectId] = !projectIdToBonus[_projectId];
    }

    /**
     * @notice Sets bonus contract for project `_projectId` to
     * `_bonusContractAddress`.
     * @param _projectId Project ID to be toggled.
     * @param _bonusContractAddress Bonus contract.
     */
    function artistSetBonusContractAddress(
        uint256 _projectId,
        address _bonusContractAddress
    ) public {
        require(
            msg.sender ==
                genArtCoreContract.projectIdToArtistAddress(_projectId),
            "can only be set by artist"
        );
        projectIdToBonusContractAddress[_projectId] = _bonusContractAddress;
    }

    /**
     * @notice Purchases a token from project `_projectId`.
     * @param _projectId Project ID to mint a token on.
     * @return _tokenId Token ID of minted token
     */
    function purchase(uint256 _projectId)
        public
        payable
        returns (uint256 _tokenId)
    {
        return purchaseTo(msg.sender, _projectId);
    }

    /**
     * @notice Purchases a token from project `_projectId` and sets
     * the token's owner to `_to`.
     * @param _to Address to be the new token's owner.
     * @param _projectId Project ID to mint a token on.
     * @return _tokenId Token ID of minted token
     */
    function purchaseTo(address _to, uint256 _projectId)
        public
        payable
        nonReentrant
        returns (uint256 _tokenId)
    {
        // CHECKS
        require(
            !projectMaxHasBeenInvoked[_projectId],
            "Maximum number of invocations reached"
        );
        // if contract filter is active prevent calls from another contract
        if (contractFilterProject[_projectId]) {
            require(msg.sender == tx.origin, "No Contract Buys");
        }

        // limit mints per address by project
        if (projectMintLimit[_projectId] > 0) {
            require(
                projectMintCounter[msg.sender][_projectId] <
                    projectMintLimit[_projectId],
                "Reached minting limit"
            );
            // EFFECTS
            projectMintCounter[msg.sender][_projectId]++;
        }

        uint256 tokenId = genArtCoreContract.mint(_to, _projectId, msg.sender);

        // What if this overflows, since default value of uint256 is 0?
        // That is intended, so that by default the minter allows infinite
        // transactions, allowing the `genArtCoreContract` to stop minting
        // `uint256 tokenInvocation = tokenId % ONE_MILLION;`
        if (
            projectMaxInvocations[_projectId] > 0 &&
            tokenId % ONE_MILLION == projectMaxInvocations[_projectId] - 1
        ) {
            projectMaxHasBeenInvoked[_projectId] = true;
        }

        // INTERACTIONS
        // bonus contract
        if (projectIdToBonus[_projectId]) {
            require(
                IBonusContract(projectIdToBonusContractAddress[_projectId])
                    .bonusIsActive(),
                "bonus must be active"
            );
            IBonusContract(projectIdToBonusContractAddress[_projectId])
                .triggerBonus(msg.sender);
        }

        // validate and split funds
        if (
            keccak256(
                abi.encodePacked(
                    genArtCoreContract.projectIdToCurrencySymbol(_projectId)
                )
            ) != keccak256(abi.encodePacked("ETH"))
        ) {
            require(
                msg.value == 0,
                "this project accepts a different currency and cannot accept ETH"
            );
            require(
                IERC20(
                    genArtCoreContract.projectIdToCurrencyAddress(_projectId)
                ).allowance(msg.sender, address(this)) >=
                    genArtCoreContract.projectIdToPricePerTokenInWei(
                        _projectId
                    ),
                "Insufficient Funds Approved for TX"
            );
            require(
                IERC20(
                    genArtCoreContract.projectIdToCurrencyAddress(_projectId)
                ).balanceOf(msg.sender) >=
                    genArtCoreContract.projectIdToPricePerTokenInWei(
                        _projectId
                    ),
                "Insufficient balance."
            );
            _splitFundsERC20(_projectId);
        } else {
            require(
                msg.value >=
                    genArtCoreContract.projectIdToPricePerTokenInWei(
                        _projectId
                    ),
                "Must send minimum value to mint!"
            );
            _splitFundsETH(_projectId);
        }

        return tokenId;
    }

    /**
     * @dev splits ETH funds between sender (if refund), foundation,
     * artist, and artist's additional payee for a token purchased on
     * project `_projectId`.
     * @dev utilizes transfer() to send ETH, so access lists may need to be
     * populated when purchasing tokens.
     */
    function _splitFundsETH(uint256 _projectId) internal {
        if (msg.value > 0) {
            uint256 pricePerTokenInWei = genArtCoreContract
                .projectIdToPricePerTokenInWei(_projectId);
            uint256 refund = msg.value -
                genArtCoreContract.projectIdToPricePerTokenInWei(_projectId);
            if (refund > 0) {
                (bool success_, ) = msg.sender.call{value: refund}("");
                require(success_, "Refund failed");
            }
            uint256 renderProviderAmount = (pricePerTokenInWei *
                genArtCoreContract.renderProviderPercentage()) / 100;
            if (renderProviderAmount > 0) {
                (bool success_, ) = genArtCoreContract
                    .renderProviderAddress()
                    .call{value: renderProviderAmount}("");
                require(success_, "Renderer payment failed");
            }

            uint256 remainingFunds = pricePerTokenInWei - renderProviderAmount;

            uint256 ownerFunds = (remainingFunds * ownerPercentage) / 100;
            if (ownerFunds > 0) {
                (bool success_, ) = ownerAddress.call{value: ownerFunds}("");
                require(success_, "Owner payment failed");
            }

            uint256 projectFunds = pricePerTokenInWei -
                renderProviderAmount -
                ownerFunds;
            uint256 additionalPayeeAmount;
            if (
                genArtCoreContract.projectIdToAdditionalPayeePercentage(
                    _projectId
                ) > 0
            ) {
                additionalPayeeAmount =
                    (projectFunds *
                        genArtCoreContract.projectIdToAdditionalPayeePercentage(
                            _projectId
                        )) /
                    100;
                if (additionalPayeeAmount > 0) {
                    (bool success_, ) = genArtCoreContract
                        .projectIdToAdditionalPayee(_projectId)
                        .call{value: additionalPayeeAmount}("");
                    require(success_, "Additional payment failed");
                }
            }
            uint256 creatorFunds = projectFunds - additionalPayeeAmount;
            if (creatorFunds > 0) {
                (bool success_, ) = genArtCoreContract
                    .projectIdToArtistAddress(_projectId)
                    .call{value: creatorFunds}("");
                require(success_, "Artist payment failed");
            }
        }
    }

    /**
     * @dev splits ERC-20 funds between render provider, owner, artist, and
     * artist's additional payee, for a token purchased on project
     `_projectId`.
     */
    function _splitFundsERC20(uint256 _projectId) internal {
        uint256 pricePerTokenInWei = genArtCoreContract
            .projectIdToPricePerTokenInWei(_projectId);
        uint256 renderProviderAmount = (pricePerTokenInWei *
            genArtCoreContract.renderProviderPercentage()) / 100;
        if (renderProviderAmount > 0) {
            IERC20(genArtCoreContract.projectIdToCurrencyAddress(_projectId))
                .transferFrom(
                    msg.sender,
                    genArtCoreContract.renderProviderAddress(),
                    renderProviderAmount
                );
        }
        uint256 remainingFunds = pricePerTokenInWei - renderProviderAmount;

        uint256 ownerFunds = (remainingFunds * ownerPercentage) / 100;
        if (ownerFunds > 0) {
            IERC20(genArtCoreContract.projectIdToCurrencyAddress(_projectId))
                .transferFrom(msg.sender, ownerAddress, ownerFunds);
        }

        uint256 projectFunds = pricePerTokenInWei -
            renderProviderAmount -
            ownerFunds;
        uint256 additionalPayeeAmount;
        if (
            genArtCoreContract.projectIdToAdditionalPayeePercentage(
                _projectId
            ) > 0
        ) {
            additionalPayeeAmount =
                (projectFunds *
                    genArtCoreContract.projectIdToAdditionalPayeePercentage(
                        _projectId
                    )) /
                100;
            if (additionalPayeeAmount > 0) {
                IERC20(
                    genArtCoreContract.projectIdToCurrencyAddress(_projectId)
                ).transferFrom(
                        msg.sender,
                        genArtCoreContract.projectIdToAdditionalPayee(
                            _projectId
                        ),
                        additionalPayeeAmount
                    );
            }
        }
        uint256 creatorFunds = projectFunds - additionalPayeeAmount;
        if (creatorFunds > 0) {
            IERC20(genArtCoreContract.projectIdToCurrencyAddress(_projectId))
                .transferFrom(
                    msg.sender,
                    genArtCoreContract.projectIdToArtistAddress(_projectId),
                    creatorFunds
                );
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

interface IGenArt721CoreV2_PBAB {
    /**
     * @notice Token ID `_tokenId` minted on project ID `_projectId` to `_to`.
     */
    event Mint(
        address indexed _to,
        uint256 indexed _tokenId,
        uint256 indexed _projectId
    );

    // getter function of public variable
    function admin() external view returns (address);

    // getter function of public variable
    function nextProjectId() external view returns (uint256);

    // getter function of public mapping
    function tokenIdToProjectId(uint256 tokenId)
        external
        view
        returns (uint256 projectId);

    function isWhitelisted(address sender) external view returns (bool);

    function projectIdToCurrencySymbol(uint256 _projectId)
        external
        view
        returns (string memory);

    function projectIdToCurrencyAddress(uint256 _projectId)
        external
        view
        returns (address);

    function projectIdToArtistAddress(uint256 _projectId)
        external
        view
        returns (address payable);

    function projectIdToPricePerTokenInWei(uint256 _projectId)
        external
        view
        returns (uint256);

    function projectIdToAdditionalPayee(uint256 _projectId)
        external
        view
        returns (address payable);

    function projectIdToAdditionalPayeePercentage(uint256 _projectId)
        external
        view
        returns (uint256);

    function projectTokenInfo(uint256 _projectId)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            bool,
            address,
            uint256,
            string memory,
            address
        );

    function renderProviderAddress() external view returns (address payable);

    function renderProviderPercentage() external view returns (uint256);

    function mint(
        address _to,
        uint256 _projectId,
        address _by
    ) external returns (uint256 tokenId);

    function getRoyaltyData(uint256 _tokenId)
        external
        view
        returns (
            address artistAddress,
            address additionalPayee,
            uint256 additionalPayeePercentage,
            uint256 royaltyFeeByID
        );
}

// SPDX-License-Identifier: LGPL-3.0-only
// Creatd By: Art Blocks Inc.

pragma solidity ^0.8.0;

interface IBonusContract {
    function triggerBonus(address _to) external returns (bool);

    function bonusIsActive() external view returns (bool);
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
pragma solidity ^0.5.0;

import './GenArt721Minter_DoodleLabs_MultiMinter.sol';
import './libs/0.5.x/Strings.sol';
import './libs/0.5.x/MerkleProof.sol';

interface IGenArt721Minter_DoodleLabs_Config {
    function getPurchaseManyLimit(uint256 projectId) external view returns (uint256 limit);

    function getState(uint256 projectId) external view returns (uint256 _state);

    function setStateFamilyCollectors(uint256 projectId) external;

    function setStateRedemption(uint256 projectId) external;

    function setStatePublic(uint256 projectId) external;
}

interface IGenArt721Minter_DoodleLabs_WhiteList {
    function getMerkleRoot(uint256 projectId) external view returns (bytes32 merkleRoot);

    function getWhitelisted(uint256 projectId, address user) external view returns (uint256 amount);

    function addWhitelist(
        uint256 projectId,
        address[] calldata users,
        uint256[] calldata amounts
    ) external;

    function increaseAmount(
        uint256 projectId,
        address to,
        uint256 quantity
    ) external;
}

contract GenArt721Minter_DoodleLabs_Custom_Sale is GenArt721Minter_DoodleLabs_MultiMinter {
    using SafeMath for uint256;

    event Redeem(uint256 projectId);

    // Must match what is on the GenArtMinterV2_State contract
    enum SaleState {
        FAMILY_COLLECTORS,
        REDEMPTION,
        PUBLIC
    }

    IGenArt721Minter_DoodleLabs_WhiteList public activeWhitelist;
    IGenArt721Minter_DoodleLabs_Config public minterState;

    modifier onlyWhitelisted() {
        require(genArtCoreContract.isWhitelisted(msg.sender), 'can only be set by admin');
        _;
    }

    modifier notRedemptionState(uint256 projectId) {
        require(
            uint256(minterState.getState(projectId)) != uint256(SaleState.REDEMPTION),
            'can not purchase in redemption phase'
        );
        _;
    }

    modifier onlyRedemptionState(uint256 projectId) {
        require(
            uint256(minterState.getState(projectId)) == uint256(SaleState.REDEMPTION),
            'not in redemption phase'
        );
        _;
    }

    constructor(address _genArtCore, address _minterStateAddress)
        public
        GenArt721Minter_DoodleLabs_MultiMinter(_genArtCore)
    {
        minterState = IGenArt721Minter_DoodleLabs_Config(_minterStateAddress);
    }

    function getMerkleRoot(uint256 projectId) public view returns (bytes32 merkleRoot) {
        require(address(activeWhitelist) != address(0), 'Active whitelist not set');
        return activeWhitelist.getMerkleRoot(projectId);
    }

    function getWhitelisted(uint256 projectId, address user)
        external
        view
        returns (uint256 amount)
    {
        require(address(activeWhitelist) != address(0), 'Active whitelist not set');
        return activeWhitelist.getWhitelisted(projectId, user);
    }

    function setActiveWhitelist(address whitelist) public onlyWhitelisted {
        activeWhitelist = IGenArt721Minter_DoodleLabs_WhiteList(whitelist);
    }

    function purchase(uint256 projectId, uint256 quantity)
        public
        payable
        notRedemptionState(projectId)
        returns (uint256[] memory _tokenIds)
    {
        return purchaseTo(msg.sender, projectId, quantity);
    }

    function purchaseTo(
        address to,
        uint256 projectId,
        uint256 quantity
    ) public payable notRedemptionState(projectId) returns (uint256[] memory _tokenIds) {
        require(
            quantity <= minterState.getPurchaseManyLimit(projectId),
            'Max purchase many limit reached'
        );
        if (
            uint256(minterState.getState(projectId)) == uint256(SaleState.FAMILY_COLLECTORS) &&
            msg.value > 0
        ) {
            require(false, 'ETH not accepted at this time');
        }
        return _purchaseManyTo(to, projectId, quantity);
    }

    function redeem(
        uint256 projectId,
        uint256 quantity,
        uint256 allottedAmount,
        bytes32[] memory proof
    ) public payable onlyRedemptionState(projectId) returns (uint256[] memory _tokenIds) {
        return redeemTo(msg.sender, projectId, quantity, allottedAmount, proof);
    }

    function redeemTo(
        address to,
        uint256 projectId,
        uint256 quantity,
        uint256 allottedAmount,
        bytes32[] memory proof
    ) public payable onlyRedemptionState(projectId) returns (uint256[] memory _tokenIds) {
        require(address(activeWhitelist) != address(0), 'Active whitelist not set');
        require(
            activeWhitelist.getWhitelisted(projectId, to).add(quantity) <= allottedAmount,
            'Address has already claimed'
        );

        string memory key = _addressToString(to);
        key = _appendStrings(key, Strings.toString(allottedAmount), Strings.toString(projectId));

        bytes32 leaf = keccak256(abi.encodePacked(key));
        require(MerkleProof.verify(proof, getMerkleRoot(projectId), leaf), 'Invalid proof');

        uint256[] memory createdTokens = _purchaseManyTo(to, projectId, quantity);

        activeWhitelist.increaseAmount(projectId, to, quantity);

        emit Redeem(projectId);
        return createdTokens;
    }

    function _appendStrings(
        string memory a,
        string memory b,
        string memory c
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(a, '::', b, '::', c));
    }

    function _addressToString(address addr) private pure returns (string memory) {
        // From: https://www.reddit.com/r/ethdev/comments/qga46a/i_created_a_function_to_convert_address_to_string/
        // Cast address to byte array
        bytes memory addressBytes = abi.encodePacked(addr);

        // Byte array for the new string
        bytes memory stringBytes = new bytes(42);

        // Assign first two bytes to '0x'
        stringBytes[0] = '0';
        stringBytes[1] = 'x';

        // Iterate over every byte in the array
        // Each byte contains two hex digits that gets individually converted
        // into their ASCII representation and added to the string
        for (uint256 i = 0; i < 20; i++) {
            // Convert hex to decimal values
            uint8 leftValue = uint8(addressBytes[i]) / 16;
            uint8 rightValue = uint8(addressBytes[i]) - 16 * leftValue;

            // Convert decimals to ASCII values
            bytes1 leftChar = leftValue < 10 ? bytes1(leftValue + 48) : bytes1(leftValue + 87);
            bytes1 rightChar = rightValue < 10 ? bytes1(rightValue + 48) : bytes1(rightValue + 87);

            // Add ASCII values to the string byte array
            stringBytes[2 * i + 3] = rightChar;
            stringBytes[2 * i + 2] = leftChar;

            // console.log(string(stringBytes));
        }

        // Cast byte array to string and return
        return string(stringBytes);
    }
}

pragma solidity ^0.5.0;

import './GenArtMinterV2_DoodleLabs.sol';
import './libs/0.5.x/SafeMath.sol';

contract GenArt721Minter_DoodleLabs_MultiMinter is GenArt721Minter_DoodleLabs {
    using SafeMath for uint256;

    event PurchaseMany(uint256 projectId, uint256 amount);
    event Purchase(uint256 _projectId);

    constructor(address _genArtCore) internal GenArt721Minter_DoodleLabs(_genArtCore) {}

    function _purchaseManyTo(
        address to,
        uint256 projectId,
        uint256 amount
    ) internal returns (uint256[] memory _tokenIds) {
        uint256[] memory tokenIds = new uint256[](amount);
        bool isDeferredRefund = false;

        // Refund ETH if user accidentially overpays
        // This is not needed for ERC20 tokens
        if (msg.value > 0) {
            uint256 pricePerTokenInWei = genArtCoreContract.projectIdToPricePerTokenInWei(
                projectId
            );
            require(msg.value >= pricePerTokenInWei.mul(amount), 'not enough funds transferred');
            uint256 refund = msg.value.sub(pricePerTokenInWei.mul(amount));
            isDeferredRefund = true;

            if (refund > 0) {
                // address payable _to = payable(to);
                address payable _to = address(uint160(to));
                _to.transfer(refund);
            }
        }

        for (uint256 i = 0; i < amount; i++) {
            tokenIds[i] = purchaseTo(to, projectId, isDeferredRefund);
            emit Purchase(projectId);
        }

        return tokenIds;
    }

    function _purchase(uint256 _projectId) internal returns (uint256 _tokenId) {
        emit Purchase(_projectId);
        return purchaseTo(msg.sender, _projectId, false);
    }
}

// File: contracts/Strings.sol

pragma solidity ^0.5.0;

//https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
library Strings {

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

    function strConcat(string memory _a, string memory _b)
        internal
        pure
        returns (string memory _concatenatedString)
    {
        return strConcat(_a, _b, '', '', '');
    }

    function strConcat(
        string memory _a,
        string memory _b,
        string memory _c
    ) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, _c, '', '');
    }

    function strConcat(
        string memory _a,
        string memory _b,
        string memory _c,
        string memory _d
    ) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, _c, _d, '');
    }

    function strConcat(
        string memory _a,
        string memory _b,
        string memory _c,
        string memory _d,
        string memory _e
    ) internal pure returns (string memory _concatenatedString) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(
            _ba.length + _bb.length + _bc.length + _bd.length + _be.length
        );
        bytes memory babcde = bytes(abcde);
        uint256 k = 0;
        uint256 i = 0;
        for (i = 0; i < _ba.length; i++) {
            babcde[k++] = _ba[i];
        }
        for (i = 0; i < _bb.length; i++) {
            babcde[k++] = _bb[i];
        }
        for (i = 0; i < _bc.length; i++) {
            babcde[k++] = _bc[i];
        }
        for (i = 0; i < _bd.length; i++) {
            babcde[k++] = _bd[i];
        }
        for (i = 0; i < _be.length; i++) {
            babcde[k++] = _be[i];
        }
        return string(babcde);
    }

    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return '0';
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + (_i % 10)));
            _i /= 10;
        }
        return string(bstr);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.5.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

/**
 *Submitted for verification at Etherscan.io on 2021-10-21
 */

pragma solidity ^0.5.0;

import './libs/0.5.x/SafeMath.sol';
import './libs/0.5.x/Strings.sol';
import './libs/0.5.x/ERC20.sol';
import './interfaces/0.5.x/IGenArt721CoreV2.sol';

interface BonusContract {
    function triggerBonus(address _to) external returns (bool);

    function bonusIsActive() external view returns (bool);
}

contract GenArt721Minter_DoodleLabs {
    using SafeMath for uint256;

    IGenArt721CoreV2 public genArtCoreContract;

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

    constructor(address _genArt721Address) public {
        genArtCoreContract = IGenArt721CoreV2(_genArt721Address);
    }

    function getYourBalanceOfProjectERC20(uint256 _projectId) public view returns (uint256) {
        uint256 balance = ERC20(genArtCoreContract.projectIdToCurrencyAddress(_projectId))
            .balanceOf(msg.sender);
        return balance;
    }

    function checkYourAllowanceOfProjectERC20(uint256 _projectId) public view returns (uint256) {
        uint256 remaining = ERC20(genArtCoreContract.projectIdToCurrencyAddress(_projectId))
            .allowance(msg.sender, address(this));
        return remaining;
    }

    function setProjectMintLimit(uint256 _projectId, uint8 _limit) public {
        require(genArtCoreContract.isWhitelisted(msg.sender), 'can only be set by admin');
        projectMintLimit[_projectId] = _limit;
    }

    function setProjectMaxInvocations(uint256 _projectId) public {
        require(genArtCoreContract.isWhitelisted(msg.sender), 'can only be set by admin');
        uint256 maxInvocations;
        uint256 invocations;
        (, , invocations, maxInvocations, , , , , ) = genArtCoreContract.projectTokenInfo(
            _projectId
        );
        projectMaxInvocations[_projectId] = maxInvocations;
        if (invocations < maxInvocations) {
            projectMaxHasBeenInvoked[_projectId] = false;
        }
    }

    function setOwnerAddress(address payable _ownerAddress) public {
        require(genArtCoreContract.isWhitelisted(msg.sender), 'can only be set by admin');
        ownerAddress = _ownerAddress;
    }

    function setOwnerPercentage(uint256 _ownerPercentage) public {
        require(genArtCoreContract.isWhitelisted(msg.sender), 'can only be set by admin');
        ownerPercentage = _ownerPercentage;
    }

    function toggleContractFilter(uint256 _projectId) public {
        require(genArtCoreContract.isWhitelisted(msg.sender), 'can only be set by admin');
        contractFilterProject[_projectId] = !contractFilterProject[_projectId];
    }

    function artistToggleBonus(uint256 _projectId) public {
        require(
            msg.sender == genArtCoreContract.projectIdToArtistAddress(_projectId),
            'can only be set by artist'
        );
        projectIdToBonus[_projectId] = !projectIdToBonus[_projectId];
    }

    function artistSetBonusContractAddress(uint256 _projectId, address _bonusContractAddress)
        public
    {
        require(
            msg.sender == genArtCoreContract.projectIdToArtistAddress(_projectId),
            'can only be set by artist'
        );
        projectIdToBonusContractAddress[_projectId] = _bonusContractAddress;
    }

    function purchase(uint256 _projectId) internal returns (uint256 _tokenId) {
        return purchaseTo(msg.sender, _projectId, false);
    }

    // Remove `public`` and `payable`` to prevent public use
    // of the `purchaseTo`` function.
    function purchaseTo(
        address _to,
        uint256 _projectId,
        bool _isDeferredRefund
    ) internal returns (uint256 _tokenId) {
        require(!projectMaxHasBeenInvoked[_projectId], 'Maximum number of invocations reached');
        if (
            keccak256(abi.encodePacked(genArtCoreContract.projectIdToCurrencySymbol(_projectId))) !=
            keccak256(abi.encodePacked('ETH'))
        ) {
            require(
                msg.value == 0,
                'this project accepts a different currency and cannot accept ETH'
            );
            require(
                ERC20(genArtCoreContract.projectIdToCurrencyAddress(_projectId)).allowance(
                    msg.sender,
                    address(this)
                ) >= genArtCoreContract.projectIdToPricePerTokenInWei(_projectId),
                'Insufficient Funds Approved for TX'
            );
            require(
                ERC20(genArtCoreContract.projectIdToCurrencyAddress(_projectId)).balanceOf(
                    msg.sender
                ) >= genArtCoreContract.projectIdToPricePerTokenInWei(_projectId),
                'Insufficient balance.'
            );
            _splitFundsERC20(_projectId);
        } else {
            require(
                msg.value >= genArtCoreContract.projectIdToPricePerTokenInWei(_projectId),
                'Must send minimum value to mint!'
            );
            _splitFundsETH(_projectId, _isDeferredRefund);
        }

        // if contract filter is active prevent calls from another contract
        if (contractFilterProject[_projectId]) require(msg.sender == tx.origin, 'No Contract Buys');

        // limit mints per address by project
        if (projectMintLimit[_projectId] > 0) {
            require(
                projectMintCounter[msg.sender][_projectId] < projectMintLimit[_projectId],
                'Reached minting limit'
            );
            projectMintCounter[msg.sender][_projectId]++;
        }

        uint256 tokenId = genArtCoreContract.mint(_to, _projectId, msg.sender);

        // What if this overflows, since default value of uint256 is 0?
        // That is intended, so that by default the minter allows infinite
        // transactions, allowing the `genArtCoreContract` to stop minting
        // `uint256 tokenInvocation = tokenId % ONE_MILLION;`
        if (tokenId % ONE_MILLION == projectMaxInvocations[_projectId] - 1) {
            projectMaxHasBeenInvoked[_projectId] = true;
        }

        if (projectIdToBonus[_projectId]) {
            require(
                BonusContract(projectIdToBonusContractAddress[_projectId]).bonusIsActive(),
                'bonus must be active'
            );
            BonusContract(projectIdToBonusContractAddress[_projectId]).triggerBonus(msg.sender);
        }

        return tokenId;
    }

    function _splitFundsETH(uint256 _projectId, bool _isDeferredRefund) internal {
        if (msg.value > 0) {
            uint256 pricePerTokenInWei = genArtCoreContract.projectIdToPricePerTokenInWei(
                _projectId
            );
            uint256 refund = msg.value.sub(
                genArtCoreContract.projectIdToPricePerTokenInWei(_projectId)
            );
            if (!_isDeferredRefund && refund > 0) {
                msg.sender.transfer(refund);
            }
            uint256 renderProviderAmount = pricePerTokenInWei.div(100).mul(
                genArtCoreContract.renderProviderPercentage()
            );
            if (renderProviderAmount > 0) {
                genArtCoreContract.renderProviderAddress().transfer(renderProviderAmount);
            }

            uint256 remainingFunds = pricePerTokenInWei.sub(renderProviderAmount);

            uint256 ownerFunds = remainingFunds.div(100).mul(ownerPercentage);
            if (ownerFunds > 0) {
                ownerAddress.transfer(ownerFunds);
            }

            uint256 projectFunds = pricePerTokenInWei.sub(renderProviderAmount).sub(ownerFunds);
            uint256 additionalPayeeAmount;
            if (genArtCoreContract.projectIdToAdditionalPayeePercentage(_projectId) > 0) {
                additionalPayeeAmount = projectFunds.div(100).mul(
                    genArtCoreContract.projectIdToAdditionalPayeePercentage(_projectId)
                );
                if (additionalPayeeAmount > 0) {
                    genArtCoreContract.projectIdToAdditionalPayee(_projectId).transfer(
                        additionalPayeeAmount
                    );
                }
            }
            uint256 creatorFunds = projectFunds.sub(additionalPayeeAmount);
            if (creatorFunds > 0) {
                genArtCoreContract.projectIdToArtistAddress(_projectId).transfer(creatorFunds);
            }
        }
    }

    function _splitFundsERC20(uint256 _projectId) internal {
        uint256 pricePerTokenInWei = genArtCoreContract.projectIdToPricePerTokenInWei(_projectId);
        uint256 renderProviderAmount = pricePerTokenInWei.div(100).mul(
            genArtCoreContract.renderProviderPercentage()
        );
        if (renderProviderAmount > 0) {
            ERC20(genArtCoreContract.projectIdToCurrencyAddress(_projectId)).transferFrom(
                msg.sender,
                genArtCoreContract.renderProviderAddress(),
                renderProviderAmount
            );
        }
        uint256 remainingFunds = pricePerTokenInWei.sub(renderProviderAmount);

        uint256 ownerFunds = remainingFunds.div(100).mul(ownerPercentage);
        if (ownerFunds > 0) {
            ERC20(genArtCoreContract.projectIdToCurrencyAddress(_projectId)).transferFrom(
                msg.sender,
                ownerAddress,
                ownerFunds
            );
        }

        uint256 projectFunds = pricePerTokenInWei.sub(renderProviderAmount).sub(ownerFunds);
        uint256 additionalPayeeAmount;
        if (genArtCoreContract.projectIdToAdditionalPayeePercentage(_projectId) > 0) {
            additionalPayeeAmount = projectFunds.div(100).mul(
                genArtCoreContract.projectIdToAdditionalPayeePercentage(_projectId)
            );
            if (additionalPayeeAmount > 0) {
                ERC20(genArtCoreContract.projectIdToCurrencyAddress(_projectId)).transferFrom(
                    msg.sender,
                    genArtCoreContract.projectIdToAdditionalPayee(_projectId),
                    additionalPayeeAmount
                );
            }
        }
        uint256 creatorFunds = projectFunds.sub(additionalPayeeAmount);
        if (creatorFunds > 0) {
            ERC20(genArtCoreContract.projectIdToCurrencyAddress(_projectId)).transferFrom(
                msg.sender,
                genArtCoreContract.projectIdToArtistAddress(_projectId),
                creatorFunds
            );
        }
    }
}

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.4.0/contracts/math/SafeMath.sol
pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.4.0/contracts/token/ERC20/ERC20.sol
pragma solidity ^0.5.0;

import './Context.sol';
import './IERC20.sol';
import './SafeMath.sol';

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                'ERC20: transfer amount exceeds allowance'
            )
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                'ERC20: decreased allowance below zero'
            )
        );
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), 'ERC20: transfer from the zero address');
        require(recipient != address(0), 'ERC20: transfer to the zero address');

        _balances[sender] = _balances[sender].sub(amount, 'ERC20: transfer amount exceeds balance');
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), 'ERC20: mint to the zero address');

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), 'ERC20: burn from the zero address');

        _balances[account] = _balances[account].sub(amount, 'ERC20: burn amount exceeds balance');
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), 'ERC20: approve from the zero address');
        require(spender != address(0), 'ERC20: approve to the zero address');

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(amount, 'ERC20: burn amount exceeds allowance')
        );
    }
}

pragma solidity ^0.5.0;

interface IGenArt721CoreV2 {
    function isWhitelisted(address sender) external view returns (bool);

    function admin() external view returns (address);

    function projectIdToCurrencySymbol(uint256 _projectId) external view returns (string memory);

    function projectIdToCurrencyAddress(uint256 _projectId) external view returns (address);

    function projectIdToArtistAddress(uint256 _projectId) external view returns (address payable);

    function projectIdToPricePerTokenInWei(uint256 _projectId) external view returns (uint256);

    function projectIdToAdditionalPayee(uint256 _projectId) external view returns (address payable);

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

    function ownerOf(uint256 tokenId) external view returns (address);

    function tokenIdToProjectId(uint256 tokenId) external view returns (uint256);
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.4.0/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol
pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
    function transferFrom(
        address sender,
        address recipient,
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
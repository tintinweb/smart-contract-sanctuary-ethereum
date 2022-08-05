// SPDX-License-Identifier: MIT
/*
+ + + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - + + +
+                                                                                                                 +
+                                                                                                                 +
.                        .^!!~:                                                 .^!!^.                            .
.                            :7Y5Y7^.                                       .^!J5Y7^.                             .
.                              :!5B#GY7^.                             .^!JP##P7:                                  .
.   7777??!         ~????7.        :[email protected]@@@&GY7^.                    .^!JG#@@@@G^        7????????????^ ~????77     .
.   @@@@@G          [email protected]@@@@:       J#@@@@@@@@@@&G57~.          .^7YG#@@@@@@@@@@&5:      #@@@@@@@@@@@@@? [email protected]@@@@@    .
.   @@@@@G          [email protected]@@@@:     :[email protected]@@@@[email protected]@@@@@@@@&B5?~:^7YG#@@@@@@@@[email protected]@@ @@&!!     #@@@@@@@@@@@@@? [email protected]@@@@@    .
.   @@@@@G          [email protected]@@@@:    [email protected]@@@#[email protected]@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@P   ^[email protected]@@@@~.   ^~~~~~^[email protected] @@@@??:~~~~~    .
.   @@@@@B^^^^^^^^. [email protected]@@@@:   [email protected]@@@&^   [email protected][email protected]@@@@@&@@@@@@@@@@@&@J7&@@@@@#.   [email protected]@@@P           [email protected]@@@@?            .
.   @@@@@@@@@@@@@@! [email protected]@@@@:   [email protected]@@@B   ^B&&@@@@@#!#@@@@@@@@@@7G&&@@@@@#!     [email protected]@@@#.           [email protected]@@@@?            .
.   @@@@@@@@@@@@@@! [email protected]@@@@:   [email protected]@@@&^    !YPGPY!  [email protected]@@@@Y&@@@@Y  ~YPGP57.    [email protected]@@@P           [email protected]@@@@?            .
.   @@@@@B~~~~~~~!!.?GPPGP:   [email protected]@@@&7           ?&@@@@P [email protected]@@@@5.          [email protected]@@@&^            [email protected]@@@@?            .
.   @@@@@G          ^~~~~~.    :[email protected]@@@@BY7~^^~75#@@@@@5.    [email protected]@@@@&P?~^^^[email protected]@@@@#~             [email protected]@@@@?            .
.   @@@@@G          [email protected]@@@@:      [email protected]@@@@@@@@@@@@@@@B!!      ^[email protected]@@@@@@@@@@@@@@@&Y               [email protected]@@@@?            .
.   @@@@@G.         [email protected]@@@@:        !YB&@@@@@@@@&BY~           ^JG#@@@@@@@@&#P7.                [email protected]@@@@?            .
.   YYYYY7          !YJJJJ.            :~!7??7!^:                 .^!7??7!~:                   ^YJJJY~            .
.                                                                                                                 .
.                                                                                                                 .
.                                                                                                                 .
.                                  ………………               …………………………………………                  …………………………………………        .
.   PBGGB??                      7&######&5            :B##############&5               .G#################^      .
.   &@@@@5                      [email protected]@@@@@@@@@           :@@@@@@@@@@@@@@@@@G               &@@@@@@@@@@@@ @@@@@^      .
.   PBBBBJ                 !!!!!JPPPPPPPPPY !!!!!     :&@@@@P?JJJJJJJJJJJJJJ?      :JJJJJJJJJJJJJJJJJJJJJJ.       .
.   ~~~~~:                .#@@@@Y          [email protected]@@@@~    :&@@@@7           [email protected]@@&.      ^@@@@.                        .
.   #@@@@Y                .#@@@@[email protected]@@@@~    :&@@@@7   !JJJJJJJJJJJJ?     :JJJJJJJJJJJJJJJJJ!!           .
.   #@@@@Y                .#@@@@@@@@@@@@@@@@@@@@@@~   :&@@@@7   [email protected]@@@@@@@G &@@             @@@@@@@@@@P            .
.   #@@@@Y                .#@@@@&##########&@@@@@~    :&@@@@7   7YYYYYYYYJ???7             JYYYYYYYYYYYYJ???7     .
.   #@@@@Y                .#@@@@5 ........ [email protected]@@@@~    :&@@@@7            [email protected]@@&.                         [email protected]@@#     .
.   #@@@@#5PPPPPPPPPJJ    .#@@@@Y          [email protected]@@@@~    :&@@@@P7??????????JYY5J      .?????????? ???????JYY5J       .
.   &@@@@@@@@@@@@@@@@@    .#@@@@Y          [email protected]@@@@~    :&@@@@@@@@@@@@@@@@@G         ^@@@@@@@@@@@@@@@@@P            .
.   PBBBBBBBBBBBBBBBBY    .#@@@@Y          [email protected]@@@@~    :&@@@@@@@@@@@@@@@@@G         ^@@@@@@@@@@@@@@@ @@5           .
+                                                                                                                 +
+                                                                                                                 +
+ + + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - + + +
*/

pragma solidity ^0.8.0;

import "../hootbase/base/erc721/HootERC721A.sol";
import "../hootbase/base/erc721/features/HootBaseERC721Raising.sol";
import "../hootbase/base/erc721/features/HootBaseERC721Refund.sol";
import "../hootbase/base/erc721/features/HootBaseERC721URISample.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

abstract contract ERC721 {
    function ownerOf(uint256 tokenId) public view virtual returns (address);
}

abstract contract YINGInterface {
    function mintTransfer(address address_, uint256 blindTokenId_)
        public
        virtual
        returns (uint256);

    function mintTransferBatch(
        address address_,
        uint256[] calldata blindTokenIds_
    ) public virtual returns (uint256[] memory);
}

/**
 * @title HootAirdropBox
 * @author HootLabs
 */
contract YINGHelloNewWorld is
    HootBaseERC721Raising,
    HootBaseERC721Refund,
    HootBaseERC721URISample,
    HootERC721A
{
    event YINGConfigChanged(YINGConfig cfg);
    event HolderMintConfigChanged(address contractAddr, HolderMintConfig cfg);
    event WhitelistSaleConfigChanged(SaleConfig cfg);
    event PartnerContractAdded(address partnerContract, uint256 maxSupply);
    event PublicSaleConfigChanged(SaleConfig cfg);
    event RevealConfigChanged(RevealConfig cfg);

    event PartnerSaled(
        address partnerContract,
        address receiver,
        uint64 amount_
    );
    /**
     * used to mark the contract, each contract have to make a different CONTRACT_SHIELD
     */
    uint256 public constant CONTRACT_SHIELD = 1942123432145421;

    struct YINGConfig {
        uint256 maxSupply;
        uint256 maxSaleSupply;
        uint256 maxSelfSupply;
        bool rejectFreeMintRefund;
    }
    struct SaleConfig {
        uint256 price;
        uint256 startTime;
        uint256 stopTime;
        uint64 supplyOfOwner;
    }
    struct HolderMintConfig {
        uint256 price;
        uint256 startTime;
        uint256 stopTime;
        uint64 supplyOfHolder;
    }
    struct RevealConfig {
        uint256 startTime;
        uint256 stopTime;
        address yingAddress;
    }

    YINGConfig public yingCfg;
    mapping(address => HolderMintConfig) _holderMintCfg;
    SaleConfig public whitelistSaleCfg;
    SaleConfig public publicSaleCfg;
    RevealConfig public revealCfg;
    mapping(address => uint64) _partnerMaxSupply;

    // contract_address => contract_token_id => amount
    mapping(address => mapping(uint256 => uint256)) _holderMintedAmounts;
    mapping(uint256 => bool) _freeMintTokens;
    mapping(uint256 => bool) _freeMintYINGTokens;
    bytes32 public merkleRoot; // merkle root for whitelist checking
    uint64 public selfMinted;

    constructor() HootERC721A("YING: Hello New World", "YING") {}

    /***********************************|
    |               Config              |
    |__________________________________*/
    function setYINGConfig(YINGConfig calldata cfg_) external onlyOwner {
        yingCfg = cfg_;
        emit YINGConfigChanged(cfg_);
    }

    function setHolderMintConfig(
        address contractAddr_,
        HolderMintConfig calldata cfg_
    ) external onlyOwner {
        _holderMintCfg[contractAddr_] = cfg_;
        emit HolderMintConfigChanged(contractAddr_, cfg_);
    }

    function setWhitelistSaleConfig(SaleConfig calldata cfg_, bytes32 root_)
        external
        onlyOwner
    {
        whitelistSaleCfg = cfg_;
        merkleRoot = root_;
        emit WhitelistSaleConfigChanged(cfg_);
    }

    function addPartnerContract(address partnerContract_, uint64 maxSupply_)
        external
        onlyOwner
    {
        _partnerMaxSupply[partnerContract_] = maxSupply_;
        emit PartnerContractAdded(partnerContract_, maxSupply_);
    }

    function setPublicSaleConfig(SaleConfig calldata cfg_) external onlyOwner {
        publicSaleCfg = cfg_;
        emit PublicSaleConfigChanged(cfg_);
    }

    // Set authorized contract address for minting the ERC-721 token
    function setRevealConfig(RevealConfig calldata cfg_) external onlyOwner {
        revealCfg = cfg_;
        emit RevealConfigChanged(cfg_);
    }

    function isWhitelistSaleEnabled() public view returns (bool) {
        return
            block.timestamp > whitelistSaleCfg.startTime &&
            block.timestamp < whitelistSaleCfg.stopTime;
    }

    function isPublicSaleEnabled() public view returns (bool) {
        return
            block.timestamp > publicSaleCfg.startTime &&
            block.timestamp < publicSaleCfg.stopTime;
    }

    // whitelist sale config
    function isWhitelistAddress(address address_, bytes32[] calldata signature_)
        public
        view
        returns (bool)
    {
        if (merkleRoot == "") {
            return false;
        }
        return
            MerkleProof.verify(
                signature_,
                merkleRoot,
                keccak256(abi.encodePacked(address_))
            );
    }

    /**
     * @notice isRevealEnabled is used to return whether the reveal has been enabled.
     */
    function isRevealEnabled() public view returns (bool) {
        return
            block.timestamp > revealCfg.startTime &&
            block.timestamp < revealCfg.stopTime &&
            revealCfg.yingAddress != address(0);
    }

    /***********************************|
    |               Core                |
    |__________________________________*/
    // The maximum number of mint tokens allowed selfSupply
    function selfMint(uint64 numberOfTokens_) external onlyOwner nonReentrant {
        require(numberOfTokens_ > 0, "invalid number of tokens");
        unchecked {
            uint64 nextMinted = selfMinted + numberOfTokens_;
            require(
                nextMinted <= yingCfg.maxSelfSupply,
                "max self supply exceeded"
            );
            _mint(_msgSender(), numberOfTokens_);
            selfMinted = nextMinted;
        }
    }

    function checkAndGetHolderConfig(address contractAddr_)
        private
        view
        returns (HolderMintConfig memory)
    {
        require(contractAddr_ != address(0), "contract address is invalid");
        HolderMintConfig memory holderCfg = _holderMintCfg[contractAddr_];
        require(
            holderCfg.startTime > 0 && block.timestamp > holderCfg.startTime,
            "holder mint is not start"
        );
        require(
            block.timestamp < holderCfg.stopTime,
            "holder mint has been stoped"
        );
        require(
            holderCfg.supplyOfHolder > 0,
            "the input contract does not support to mint"
        );
        return holderCfg;
    }

    function holdersSale(
        address contractAddr_,
        uint256[] calldata tokenIDs_,
        uint64[] calldata amounts_
    ) external payable callerIsUser nonReentrant {
        require(
            tokenIDs_.length == amounts_.length,
            "the length of Listing TokenIDs is different from that of Listing Amounts"
        );
        HolderMintConfig memory holderCfg = checkAndGetHolderConfig(
            contractAddr_
        );
        require(
            tokenIDs_.length < yingCfg.maxSaleSupply,
            "max sale supply exceeded"
        );

        uint64 amountTotal = 0;
        unchecked {
            for (uint256 i = 0; i < tokenIDs_.length; i++) {
                uint64 amount = amounts_[i];
                require(amount < 3, "an token can only mint two tokens");
                require(amount > 0, "invalid number of tokens");

                uint256 nextSupply = _holderMintedAmounts[contractAddr_][
                    tokenIDs_[i]
                ] + amount;
                require(
                    nextSupply <= holderCfg.supplyOfHolder,
                    "max sale supply exceeded"
                );

                // 验证是否是 owner
                ERC721 contractAddress = ERC721(contractAddr_);
                require(
                    contractAddress.ownerOf(tokenIDs_[i]) == _msgSender(),
                    "doesn't own the token"
                );
                _holderMintedAmounts[contractAddr_][tokenIDs_[i]] = nextSupply;

                amountTotal += amount;
            }
            _sale(_msgSender(), amountTotal, holderCfg.price);
        }
    }

    // Only one token can be mint at a time
    function whitelistSale(bytes32[] calldata signature_, uint64 amount_)
        external
        payable
        callerIsUser
        nonReentrant
    {
        require(isWhitelistSaleEnabled(), "whitelist sale has not enabled");
        require(
            isWhitelistAddress(_msgSender(), signature_),
            "caller is not in whitelist or invalid signature"
        );
        require(amount_ > 0, "invalid number of tokens");
        require(amount_ < 3, "can only mint 2 tokens at a time");

        uint64 nextSupply = _getAux(_msgSender()) + amount_;
        require(
            nextSupply <= whitelistSaleCfg.supplyOfOwner,
            "out of max mint amount"
        );
        _sale(_msgSender(), amount_, whitelistSaleCfg.price);
        _setAux(_msgSender(), uint64(nextSupply));
    }

    function partnerSale(address receiver, uint64 amount_)
        external
        payable
        nonReentrant
    {
        require(isWhitelistSaleEnabled(), "whitelist sale has not enabled");
        require(amount_ > 0, "invalid number of tokens");
        require(amount_ < 3, "can only mint 2 tokens at a time");

        uint64 maxSupply = _partnerMaxSupply[_msgSender()];
        uint64 nextSupply = _getAux(_msgSender()) + amount_;
        require(nextSupply <= maxSupply, "out of max mint amount");

        _sale(receiver, amount_, whitelistSaleCfg.price);
        _setAux(_msgSender(), uint64(nextSupply));

        emit PartnerSaled(_msgSender(), receiver, amount_);
    }

    /**
     * @notice public sale.
     * @param amount_ sale amount
     */
    function publicSale(uint64 amount_)
        external
        payable
        callerIsUser
        nonReentrant
    {
        require(isPublicSaleEnabled(), "public sale has not enabled");
        require(amount_ > 0, "invalid number of tokens");
        require(amount_ < 3, "can only mint 2 tokens at a time");

        uint64 nextSupply = _getAux(_msgSender()) + amount_;
        require(
            nextSupply <= publicSaleCfg.supplyOfOwner,
            "out of max mint amount"
        );
        _sale(_msgSender(), amount_, publicSaleCfg.price);
        _setAux(_msgSender(), nextSupply);
    }

    // The maximum number of mint tokens allowed saleSupply
    function _sale(
        address receiver,
        uint64 numberOfTokens_,
        uint256 price_
    ) internal {
        require(
            _totalMinted() + numberOfTokens_ - selfMinted <= yingCfg.maxSaleSupply,
            "max sale supply exceeded"
        );
        uint256 amount = price_ * numberOfTokens_;
        require(amount <= msg.value, "ether value sent is not correct");
        _safeMint(receiver, numberOfTokens_);
        refundExcessPayment(amount);
        if (price_ == 0) {
            for (uint256 i = 0; i < numberOfTokens_; ++i) {
                _freeMintTokens[_totalMinted() - i] = true;
            }
        }
    }

    /**
     * @notice when the amount paid by the user exceeds the actual need, the refund logic will be executed.
     * @param amount_ the actual amount that should be paid
     */
    function refundExcessPayment(uint256 amount_) private {
        if (msg.value > amount_) {
            payable(_msgSender()).transfer(msg.value - amount_);
        }
    }

    /**
     * @notice Determine whether it is the Token of a FreeMint
     * @param tokenId_ YING: Hello New World token id
     */
    function isFreeMintToken(uint256 tokenId_)
        public
        view
        virtual
        returns (bool)
    {
        return _freeMintTokens[tokenId_];
    }

    /**
     * @notice Determine whether it is the Token of a FreeMint
     * @param tokenId_ YING token id
     */
    function isFreeMintYINGToken(uint256 tokenId_)
        public
        view
        virtual
        returns (bool)
    {
        return _freeMintYINGTokens[tokenId_];
    }

    /**
     * Gets the number of Mint of the holder
     */
    function getHolderMinted(
        address contractAddr_,
        uint256[] calldata tokenIDs_
    ) external view returns (uint256[] memory) {
        mapping(uint256 => uint256) storage tokenAmount = _holderMintedAmounts[
            contractAddr_
        ];
        uint256[] memory amounts = new uint256[](tokenIDs_.length);
        for (uint256 i = 0; i < tokenIDs_.length; i++) {
            amounts[i] = tokenAmount[tokenIDs_[i]];
        }
        return amounts;
    }

    /**
     * gets the number of Mint during the whitelist and the public sale
     */
    function getSaleBalanceOf(address owner) public view returns (uint256) {
       return _getAux(owner);
    }

    /**
     * @notice reveal is used to open the blind box.
     * @param tokenId_ tokenId of the blind box to be revealed.
     * @return tokenId after revealing the blind box.
     */
    function reveal(uint256 tokenId_)
        external
        callerIsUser
        nonReentrant
        returns (uint256)
    {
        require(isRevealEnabled(), "reveal has not enabled");
        require(ownerOf(tokenId_) == _msgSender(), "caller is not owner");
        _burn(tokenId_);
        YINGInterface yingContract = YINGInterface(revealCfg.yingAddress);
        uint256 yingTokenId = yingContract.mintTransfer(_msgSender(), tokenId_);
        if (isFreeMintToken(tokenId_)) {
            _freeMintYINGTokens[yingTokenId] = true;
        }
        return yingTokenId;
    }

    function revealBatch(uint256[] calldata tokenIds_)
        external
        callerIsUser
        nonReentrant
        returns (uint256[] memory)
    {
        require(isRevealEnabled(), "reveal has not enabled");
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            uint256 tokenId = tokenIds_[i];
            require(ownerOf(tokenId) == _msgSender(), "caller is not owner");
            _burn(tokenId);
        }
        YINGInterface yingContract = YINGInterface(revealCfg.yingAddress);
        uint256[] memory yingTokenIds = yingContract.mintTransferBatch(
            _msgSender(),
            tokenIds_
        );
        for (uint256 i = 0; i < yingTokenIds.length; i++) {
            if (isFreeMintToken(tokenIds_[i])) {
                _freeMintYINGTokens[yingTokenIds[i]] = true;
            }
        }
        return yingTokenIds;
    }

    /***********************************|
    |        HootBaseERC721Refund       |
    |__________________________________*/
    function _refundPrice(uint256 tokenId_)
        internal
        view
        virtual
        override
        returns (uint256)
    {
        if (yingCfg.rejectFreeMintRefund) {
            require(
                !_freeMintTokens[tokenId_],
                "No refunds are allowed for free mint token"
            );
        }
        return super._refundPrice(tokenId_);
    }

    /***********************************|
    | HootBaseERC721URIStorageWithLevel |
    |__________________________________*/
    function tokenURI(uint256 tokenId_)
        public
        view
        virtual
        override(ERC721A, HootBaseERC721URISample)
        returns (string memory)
    {
        return HootBaseERC721URISample.tokenURI(tokenId_);
    }

    /***********************************|
    |               ERC721A             |
    |__________________________________*/
    /**
     * @notice hook function, used to intercept the transfer of token.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override(HootBaseERC721Raising, HootERC721A) {
        HootBaseERC721Raising._beforeTokenTransfers(
            from,
            to,
            startTokenId,
            quantity
        );
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
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
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
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
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
/*
+ + + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - + + +
+                                                                                                                 +
+                                                                                                                 +
.                        .^!!~:                                                 .^!!^.                            .
.                            :7Y5Y7^.                                       .^!J5Y7^.                             .
.                              :!5B#GY7^.                             .^!JP##P7:                                  .
.   7777??!         ~????7.        :[email protected]@@@&GY7^.                    .^!JG#@@@@G^        7????????????^ ~????77     .
.   @@@@@G          [email protected]@@@@:       J#@@@@@@@@@@&G57~.          .^7YG#@@@@@@@@@@&5:      #@@@@@@@@@@@@@? [email protected]@@@@@    .
.   @@@@@G          [email protected]@@@@:     :[email protected]@@@@[email protected]@@@@@@@@&B5?~:^7YG#@@@@@@@@[email protected]@@ @@&!!     #@@@@@@@@@@@@@? [email protected]@@@@@    .
.   @@@@@G          [email protected]@@@@:    [email protected]@@@#[email protected]@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@P   ^[email protected]@@@@~.   ^~~~~~^[email protected] @@@@??:~~~~~    .
.   @@@@@B^^^^^^^^. [email protected]@@@@:   [email protected]@@@&^   [email protected][email protected]@@@@@&@@@@@@@@@@@&@J7&@@@@@#.   [email protected]@@@P           [email protected]@@@@?            .
.   @@@@@@@@@@@@@@! [email protected]@@@@:   [email protected]@@@B   ^B&&@@@@@#!#@@@@@@@@@@7G&&@@@@@#!     [email protected]@@@#.           [email protected]@@@@?            .
.   @@@@@@@@@@@@@@! [email protected]@@@@:   [email protected]@@@&^    !YPGPY!  [email protected]@@@@Y&@@@@Y  ~YPGP57.    [email protected]@@@P           [email protected]@@@@?            .
.   @@@@@B~~~~~~~!!.?GPPGP:   [email protected]@@@&7           ?&@@@@P [email protected]@@@@5.          [email protected]@@@&^            [email protected]@@@@?            .
.   @@@@@G          ^~~~~~.    :[email protected]@@@@BY7~^^~75#@@@@@5.    [email protected]@@@@&P?~^^^[email protected]@@@@#~             [email protected]@@@@?            .
.   @@@@@G          [email protected]@@@@:      [email protected]@@@@@@@@@@@@@@@B!!      ^[email protected]@@@@@@@@@@@@@@@&Y               [email protected]@@@@?            .
.   @@@@@G.         [email protected]@@@@:        !YB&@@@@@@@@&BY~           ^JG#@@@@@@@@&#P7.                [email protected]@@@@?            .
.   YYYYY7          !YJJJJ.            :~!7??7!^:                 .^!7??7!~:                   ^YJJJY~            .
.                                                                                                                 .
.                                                                                                                 .
.                                                                                                                 .
.                                  ………………               …………………………………………                  …………………………………………        .
.   PBGGB??                      7&######&5            :B##############&5               .G#################^      .
.   &@@@@5                      [email protected]@@@@@@@@@           :@@@@@@@@@@@@@@@@@G               &@@@@@@@@@@@@ @@@@@^      .
.   PBBBBJ                 !!!!!JPPPPPPPPPY !!!!!     :&@@@@P?JJJJJJJJJJJJJJ?      :JJJJJJJJJJJJJJJJJJJJJJ.       .
.   ~~~~~:                .#@@@@Y          [email protected]@@@@~    :&@@@@7           [email protected]@@&.      ^@@@@.                        .
.   #@@@@Y                .#@@@@[email protected]@@@@~    :&@@@@7   !JJJJJJJJJJJJ?     :JJJJJJJJJJJJJJJJJ!!           .
.   #@@@@Y                .#@@@@@@@@@@@@@@@@@@@@@@~   :&@@@@7   [email protected]@@@@@@@G &@@             @@@@@@@@@@P            .
.   #@@@@Y                .#@@@@&##########&@@@@@~    :&@@@@7   7YYYYYYYYJ???7             JYYYYYYYYYYYYJ???7     .
.   #@@@@Y                .#@@@@5 ........ [email protected]@@@@~    :&@@@@7            [email protected]@@&.                         [email protected]@@#     .
.   #@@@@#5PPPPPPPPPJJ    .#@@@@Y          [email protected]@@@@~    :&@@@@P7??????????JYY5J      .?????????? ???????JYY5J       .
.   &@@@@@@@@@@@@@@@@@    .#@@@@Y          [email protected]@@@@~    :&@@@@@@@@@@@@@@@@@G         ^@@@@@@@@@@@@@@@@@P            .
.   PBBBBBBBBBBBBBBBBY    .#@@@@Y          [email protected]@@@@~    :&@@@@@@@@@@@@@@@@@G         ^@@@@@@@@@@@@@@@ @@5           .
+                                                                                                                 +
+                                                                                                                 +
+ + + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - + + +
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "../../common/HootBase.sol";
import "../extensions/HootBaseERC721Owners.sol";

/**
 * @title HootBaseERC721URISample
 * @author HootLabs
 */
abstract contract HootBaseERC721URISample is
    HootBase,
    HootBaseERC721Owners,
    IERC721,
    IERC721Metadata
{
    using Strings for uint256;

    event BaseURIChanged(string uri);

    string private _preURI;

    function _baseURI(
        uint256 /* tokenId_*/
    ) internal view virtual returns (string memory) {
        return _preURI;
    }

    function setBaseURI(string calldata uri_) external onlyOwner {
        _preURI = uri_;
        emit BaseURIChanged(uri_);
    }

    function tokenURI(uint256 tokenId_)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(this.exists(tokenId_), "token is not exist");

        string memory baseURI = _baseURI(tokenId_);
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId_.toString()))
                : "";
    }

    function unsafeTokenURIBatch(uint256[] calldata tokenIds_)
        public
        view
        virtual
        returns (string[] memory)
    {
        string[] memory uris = new string[](tokenIds_.length);
        for (uint256 i = 0; i < tokenIds_.length; ++i) {
            uint256 tokenId = tokenIds_[i];
            if(!this.exists(tokenId)){
                uris[i]="";
                continue;
            }
            string memory baseURI = _baseURI(tokenId);
            uris[i] = bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
        }
        return uris;
    }
}

// SPDX-License-Identifier: MIT
/*
+ + + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - + + +
+                                                                                                                 +
+                                                                                                                 +
.                        .^!!~:                                                 .^!!^.                            .
.                            :7Y5Y7^.                                       .^!J5Y7^.                             .
.                              :!5B#GY7^.                             .^!JP##P7:                                  .
.   7777??!         ~????7.        :[email protected]@@@&GY7^.                    .^!JG#@@@@G^        7????????????^ ~????77     .
.   @@@@@G          [email protected]@@@@:       J#@@@@@@@@@@&G57~.          .^7YG#@@@@@@@@@@&5:      #@@@@@@@@@@@@@? [email protected]@@@@@    .
.   @@@@@G          [email protected]@@@@:     :[email protected]@@@@[email protected]@@@@@@@@&B5?~:^7YG#@@@@@@@@[email protected]@@ @@&!!     #@@@@@@@@@@@@@? [email protected]@@@@@    .
.   @@@@@G          [email protected]@@@@:    [email protected]@@@#[email protected]@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@P   ^[email protected]@@@@~.   ^~~~~~^[email protected] @@@@??:~~~~~    .
.   @@@@@B^^^^^^^^. [email protected]@@@@:   [email protected]@@@&^   [email protected][email protected]@@@@@&@@@@@@@@@@@&@J7&@@@@@#.   [email protected]@@@P           [email protected]@@@@?            .
.   @@@@@@@@@@@@@@! [email protected]@@@@:   [email protected]@@@B   ^B&&@@@@@#!#@@@@@@@@@@7G&&@@@@@#!     [email protected]@@@#.           [email protected]@@@@?            .
.   @@@@@@@@@@@@@@! [email protected]@@@@:   [email protected]@@@&^    !YPGPY!  [email protected]@@@@Y&@@@@Y  ~YPGP57.    [email protected]@@@P           [email protected]@@@@?            .
.   @@@@@B~~~~~~~!!.?GPPGP:   [email protected]@@@&7           ?&@@@@P [email protected]@@@@5.          [email protected]@@@&^            [email protected]@@@@?            .
.   @@@@@G          ^~~~~~.    :[email protected]@@@@BY7~^^~75#@@@@@5.    [email protected]@@@@&P?~^^^[email protected]@@@@#~             [email protected]@@@@?            .
.   @@@@@G          [email protected]@@@@:      [email protected]@@@@@@@@@@@@@@@B!!      ^[email protected]@@@@@@@@@@@@@@@&Y               [email protected]@@@@?            .
.   @@@@@G.         [email protected]@@@@:        !YB&@@@@@@@@&BY~           ^JG#@@@@@@@@&#P7.                [email protected]@@@@?            .
.   YYYYY7          !YJJJJ.            :~!7??7!^:                 .^!7??7!~:                   ^YJJJY~            .
.                                                                                                                 .
.                                                                                                                 .
.                                                                                                                 .
.                                  ………………               …………………………………………                  …………………………………………        .
.   PBGGB??                      7&######&5            :B##############&5               .G#################^      .
.   &@@@@5                      [email protected]@@@@@@@@@           :@@@@@@@@@@@@@@@@@G               &@@@@@@@@@@@@ @@@@@^      .
.   PBBBBJ                 !!!!!JPPPPPPPPPY !!!!!     :&@@@@P?JJJJJJJJJJJJJJ?      :JJJJJJJJJJJJJJJJJJJJJJ.       .
.   ~~~~~:                .#@@@@Y          [email protected]@@@@~    :&@@@@7           [email protected]@@&.      ^@@@@.                        .
.   #@@@@Y                .#@@@@[email protected]@@@@~    :&@@@@7   !JJJJJJJJJJJJ?     :JJJJJJJJJJJJJJJJJ!!           .
.   #@@@@Y                .#@@@@@@@@@@@@@@@@@@@@@@~   :&@@@@7   [email protected]@@@@@@@G &@@             @@@@@@@@@@P            .
.   #@@@@Y                .#@@@@&##########&@@@@@~    :&@@@@7   7YYYYYYYYJ???7             JYYYYYYYYYYYYJ???7     .
.   #@@@@Y                .#@@@@5 ........ [email protected]@@@@~    :&@@@@7            [email protected]@@&.                         [email protected]@@#     .
.   #@@@@#5PPPPPPPPPJJ    .#@@@@Y          [email protected]@@@@~    :&@@@@P7??????????JYY5J      .?????????? ???????JYY5J       .
.   &@@@@@@@@@@@@@@@@@    .#@@@@Y          [email protected]@@@@~    :&@@@@@@@@@@@@@@@@@G         ^@@@@@@@@@@@@@@@@@P            .
.   PBBBBBBBBBBBBBBBBY    .#@@@@Y          [email protected]@@@@~    :&@@@@@@@@@@@@@@@@@G         ^@@@@@@@@@@@@@@@ @@5           .
+                                                                                                                 +
+                                                                                                                 +
+ + + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - + + +
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../../common/HootBase.sol";

/**
 * @title HootBaseERC721Refund
 * @author HootLabs
 */
abstract contract HootBaseERC721Refund is HootBase, IERC721 {
    using Address for address;

    event RefundConfigChanged(RefundConfig config);
    event RefundAddressChanged(address indexed refundAddress);
    event Refunded(address indexed from, address indexed to, uint256 tokenId, uint256 amount);

    constructor(){
        refundAddress = _msgSender();
    }
    // mint State Variables
    address public refundAddress;

    struct RefundConfig {
        uint256 startTime;
        uint256 stopTime;
        uint256 price;
    }
    RefundConfig public refundConfig;

    // refund config
    function isRefundEnabled() public view virtual returns (bool) {
        return block.timestamp > refundConfig.startTime && block.timestamp < refundConfig.stopTime;
    }
    function setRefundAddress(address refundAddress_) external onlyOwner {
        refundAddress = refundAddress_;
        emit RefundAddressChanged(refundAddress_);
    }
    function setRefundConfig(RefundConfig calldata cfg_) external onlyOwner {
        refundConfig = cfg_;
        emit RefundConfigChanged(refundConfig);
    }

    function _refundPrice(uint256 /*tokenId_*/) internal view virtual returns (uint256) {
        return refundConfig.price;
    }

    // refund
    function refund(uint256 tokenId_) external callerIsUser nonReentrant {
        require(_msgSender() == this.ownerOf(tokenId_), "not token owner");
        require(_msgSender() != refundAddress, "stock account refunds are not allowed");
        require(isRefundEnabled(), "outside the refundable period");

        uint256 refundPrice = _refundPrice(tokenId_);
        require(refundPrice > 0, "only sale NFT can be refunded");
        require(address(this).balance >= refundPrice, "insufficient contract funds");

        this.safeTransferFrom(_msgSender(), refundAddress, tokenId_);
        //Address.sendValue(payable(_msgSender()), refundPrice);
        payable(_msgSender()).transfer(refundPrice);

        emit Refunded(_msgSender(), refundAddress, tokenId_, refundPrice);
    }
}

// SPDX-License-Identifier: MIT
/*
+ + + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - + + +
+                                                                                                                 +
+                                                                                                                 +
.                        .^!!~:                                                 .^!!^.                            .
.                            :7Y5Y7^.                                       .^!J5Y7^.                             .
.                              :!5B#GY7^.                             .^!JP##P7:                                  .
.   7777??!         ~????7.        :[email protected]@@@&GY7^.                    .^!JG#@@@@G^        7????????????^ ~????77     .
.   @@@@@G          [email protected]@@@@:       J#@@@@@@@@@@&G57~.          .^7YG#@@@@@@@@@@&5:      #@@@@@@@@@@@@@? [email protected]@@@@@    .
.   @@@@@G          [email protected]@@@@:     :[email protected]@@@@[email protected]@@@@@@@@&B5?~:^7YG#@@@@@@@@[email protected]@@ @@&!!     #@@@@@@@@@@@@@? [email protected]@@@@@    .
.   @@@@@G          [email protected]@@@@:    [email protected]@@@#[email protected]@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@P   ^[email protected]@@@@~.   ^~~~~~^[email protected] @@@@??:~~~~~    .
.   @@@@@B^^^^^^^^. [email protected]@@@@:   [email protected]@@@&^   [email protected][email protected]@@@@@&@@@@@@@@@@@&@J7&@@@@@#.   [email protected]@@@P           [email protected]@@@@?            .
.   @@@@@@@@@@@@@@! [email protected]@@@@:   [email protected]@@@B   ^B&&@@@@@#!#@@@@@@@@@@7G&&@@@@@#!     [email protected]@@@#.           [email protected]@@@@?            .
.   @@@@@@@@@@@@@@! [email protected]@@@@:   [email protected]@@@&^    !YPGPY!  [email protected]@@@@Y&@@@@Y  ~YPGP57.    [email protected]@@@P           [email protected]@@@@?            .
.   @@@@@B~~~~~~~!!.?GPPGP:   [email protected]@@@&7           ?&@@@@P [email protected]@@@@5.          [email protected]@@@&^            [email protected]@@@@?            .
.   @@@@@G          ^~~~~~.    :[email protected]@@@@BY7~^^~75#@@@@@5.    [email protected]@@@@&P?~^^^[email protected]@@@@#~             [email protected]@@@@?            .
.   @@@@@G          [email protected]@@@@:      [email protected]@@@@@@@@@@@@@@@B!!      ^[email protected]@@@@@@@@@@@@@@@&Y               [email protected]@@@@?            .
.   @@@@@G.         [email protected]@@@@:        !YB&@@@@@@@@&BY~           ^JG#@@@@@@@@&#P7.                [email protected]@@@@?            .
.   YYYYY7          !YJJJJ.            :~!7??7!^:                 .^!7??7!~:                   ^YJJJY~            .
.                                                                                                                 .
.                                                                                                                 .
.                                                                                                                 .
.                                  ………………               …………………………………………                  …………………………………………        .
.   PBGGB??                      7&######&5            :B##############&5               .G#################^      .
.   &@@@@5                      [email protected]@@@@@@@@@           :@@@@@@@@@@@@@@@@@G               &@@@@@@@@@@@@ @@@@@^      .
.   PBBBBJ                 !!!!!JPPPPPPPPPY !!!!!     :&@@@@P?JJJJJJJJJJJJJJ?      :JJJJJJJJJJJJJJJJJJJJJJ.       .
.   ~~~~~:                .#@@@@Y          [email protected]@@@@~    :&@@@@7           [email protected]@@&.      ^@@@@.                        .
.   #@@@@Y                .#@@@@[email protected]@@@@~    :&@@@@7   !JJJJJJJJJJJJ?     :JJJJJJJJJJJJJJJJJ!!           .
.   #@@@@Y                .#@@@@@@@@@@@@@@@@@@@@@@~   :&@@@@7   [email protected]@@@@@@@G &@@             @@@@@@@@@@P            .
.   #@@@@Y                .#@@@@&##########&@@@@@~    :&@@@@7   7YYYYYYYYJ???7             JYYYYYYYYYYYYJ???7     .
.   #@@@@Y                .#@@@@5 ........ [email protected]@@@@~    :&@@@@7            [email protected]@@&.                         [email protected]@@#     .
.   #@@@@#5PPPPPPPPPJJ    .#@@@@Y          [email protected]@@@@~    :&@@@@P7??????????JYY5J      .?????????? ???????JYY5J       .
.   &@@@@@@@@@@@@@@@@@    .#@@@@Y          [email protected]@@@@~    :&@@@@@@@@@@@@@@@@@G         ^@@@@@@@@@@@@@@@@@P            .
.   PBBBBBBBBBBBBBBBBY    .#@@@@Y          [email protected]@@@@~    :&@@@@@@@@@@@@@@@@@G         ^@@@@@@@@@@@@@@@ @@5           .
+                                                                                                                 +
+                                                                                                                 +
+ + + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - + + +
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../../common/HootBase.sol";
import "../extensions/HootBaseERC721Owners.sol";

/**
 * @title HootBaseERC721Raising
 * @author HootLabs
 */
abstract contract HootBaseERC721Raising is
    HootBase,
    HootBaseERC721Owners,
    IERC721
{
    event RaisingStatusChanged(
        uint256 indexed tokenId,
        address indexed owner,
        uint16 indexed raisingType,
        bool isStart
    );
    event RaisingInterrupted(uint256 indexed tokenId, address indexed operator);
    event RaisingTokenTransfered(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event RaisingAllowedFlagChanged(
        bool isRaisingAllowed,
        bool isRaisingTransferAllowed
    );

    struct RaisingStatus {
        uint256 raisingStartTime;
        uint256 total;
        uint16 raisingType;
        bool provisionalFree;
    }
    struct RaisingCurrentStatus {
        uint256 total;
        uint256 current;
        uint16 raisingType;
        bool isRaising;
    }
    mapping(uint256 => RaisingStatus) private _raisingStatuses;
    bool public isRaisingAllowed;
    bool public isRaisingTransferAllowed;

    /***********************************|
    |               Raising Config      |
    |__________________________________*/
    /**
     * @notice setIsRaisingAllowed is used to set the global switch to control whether users are allowed to brew.
     * @param isRaisingAllowed_ set to true to allow
     */
    function setIsRaisingAllowed(
        bool isRaisingAllowed_,
        bool isRaisingTransferAllowed_
    ) external atLeastMaintainer {
        isRaisingAllowed = isRaisingAllowed_;
        isRaisingTransferAllowed = isRaisingTransferAllowed_;
        emit RaisingAllowedFlagChanged(
            isRaisingAllowed_,
            isRaisingTransferAllowed_
        );
    }

    /***********************************|
    |               Raising Core        |
    |__________________________________*/
    /**
     * @notice safeTransferWhileRaising is used to safely transfer tokens while raising
     * @param from_ transfer from address, cannot be the zero.
     * @param to_ transfer to address, cannot be the zero.
     * @param tokenId_ token must exist and be owned by `from`.
     */
    function safeTransferWhileRaising(
        address from_,
        address to_,
        uint256 tokenId_
    ) external nonReentrant {
        require(this.ownerOf(tokenId_) == _msgSender(), "caller is not owner");
        require(
            isRaisingTransferAllowed,
            "transfer while raising is not enabled"
        );
        _raisingStatuses[tokenId_].provisionalFree = true;
        this.safeTransferFrom(from_, to_, tokenId_);
        _raisingStatuses[tokenId_].provisionalFree = false;
        if (_raisingStatuses[tokenId_].raisingStartTime != 0) {
            emit RaisingTokenTransfered(from_, to_, tokenId_);
        }
    }

    /**
     * @notice getTokenRaisingStatus is used to get the detailed raising status of a specific token.
     * @param tokenIDs_ token id
     * @return RaisingCurrentStatus[] how long the token has been raising in the hands of the current hodler.
     */
    function getTokenRaisingStatus(uint256[] calldata tokenIDs_)
        external
        view
        returns (RaisingCurrentStatus[] memory)
    {
        RaisingCurrentStatus[] memory statusList = new RaisingCurrentStatus[](tokenIDs_.length);
        for (uint256 i = 0; i < tokenIDs_.length; ++i) {
            uint256 tokenId = tokenIDs_[i];
            if(!this.exists(tokenId)){
                continue;
            }
            RaisingStatus memory status = _raisingStatuses[tokenId];
            if (status.raisingStartTime != 0) {
                statusList[i].isRaising = true;
                statusList[i].raisingType = status.raisingType;
                statusList[i].current = block.timestamp - status.raisingStartTime;
            }
            statusList[i].total = status.total + statusList[i].current;
        }
        return statusList;
    }

    function _isTokenRaising(uint256 tokenId_) internal view returns (bool) {
        return _raisingStatuses[tokenId_].raisingStartTime != 0;
    }

    /**
     * @notice setTokenRaisingState is used to modify the Raising state of the Token,
     * only the Owner of the Token has this permission.
     * @param tokenIds_ list of tokenId
     */
    function doTokenRaising(
        uint256[] calldata tokenIds_,
        uint16 raisingType_,
        bool isStart_
    ) external nonReentrant {
        if (isStart_) {
            require(isRaisingAllowed, "raising is not allowed");
        }
        unchecked {
            for (uint256 i = 0; i < tokenIds_.length; i++) {
                uint256 tokenId = tokenIds_[i];
                require(
                    this.ownerOf(tokenId) == _msgSender(),
                    "caller is not owner"
                );

                RaisingStatus storage status = _raisingStatuses[tokenId];
                uint256 raisingStartTime = status.raisingStartTime;
                if (isStart_) {
                    if (raisingStartTime == 0) {
                        status.raisingStartTime = block.timestamp;
                        status.raisingType = raisingType_;
                        emit RaisingStatusChanged(
                            tokenId,
                            _msgSender(),
                            raisingType_,
                            isStart_
                        );
                    } else {
                        require(
                            status.raisingType == raisingType_,
                            "raising is already started, but with a different raising type set"
                        );
                    }
                } else {
                    if (raisingStartTime > 0) {
                        status.total += block.timestamp - raisingStartTime;
                        status.raisingStartTime = 0;
                        emit RaisingStatusChanged(
                            tokenId,
                            _msgSender(),
                            raisingType_,
                            isStart_
                        );
                    }
                }
            }
        }
    }

    /**
     * @notice interruptTokenRaising gives the issuer the right to forcibly interrupt the raising state of the token.
     * One scenario of using it is: someone may maliciously place low-priced raising tokens on
     * the secondary market (because raising tokens cannot be traded).
     * @param tokenIds_ the tokenId list to operate
     */
    function interruptTokenRaising(uint256[] calldata tokenIds_)
        external
        nonReentrant
        atLeastMaintainer
    {
        unchecked {
            for (uint256 i = 0; i < tokenIds_.length; i++) {
                uint256 tokenId = tokenIds_[i];
                address owner = this.ownerOf(tokenId);
                RaisingStatus storage status = _raisingStatuses[tokenId];
                if (status.raisingStartTime == 0) {
                    continue;
                }
                status.total += block.timestamp - status.raisingStartTime;
                status.raisingStartTime = 0;
                emit RaisingStatusChanged(
                    tokenId,
                    owner,
                    status.raisingType,
                    false
                );
                emit RaisingInterrupted(tokenId, _msgSender());
            }
        }
    }

    function _beforeTokenTransfer(
        address, /*from_*/
        address, /*to_*/
        uint256 tokenId_
    ) internal virtual {
        if (_isTokenRaising(tokenId_)) {
            require(
                _raisingStatuses[tokenId_].provisionalFree,
                "token is raising"
            );
        }
    }

    function _beforeTokenTransfers(
        address, /*from_*/
        address, /*to_*/
        uint256 startTokenId_,
        uint256 quantity_
    ) internal virtual {
        for (uint256 i = 0; i < quantity_; ++i) {
            if (_isTokenRaising(startTokenId_ + i)) {
                require(
                    _raisingStatuses[startTokenId_ + i].provisionalFree,
                    "token is raising"
                );
            }
        }
    }
}

// SPDX-License-Identifier: MIT
/*
+ + + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - + + +
+                                                                                                                 +
+                                                                                                                 +
.                        .^!!~:                                                 .^!!^.                            .
.                            :7Y5Y7^.                                       .^!J5Y7^.                             .
.                              :!5B#GY7^.                             .^!JP##P7:                                  .
.   7777??!         ~????7.        :[email protected]@@@&GY7^.                    .^!JG#@@@@G^        7????????????^ ~????77     .
.   @@@@@G          [email protected]@@@@:       J#@@@@@@@@@@&G57~.          .^7YG#@@@@@@@@@@&5:      #@@@@@@@@@@@@@? [email protected]@@@@@    .
.   @@@@@G          [email protected]@@@@:     :[email protected]@@@@[email protected]@@@@@@@@&B5?~:^7YG#@@@@@@@@[email protected]@@ @@&!!     #@@@@@@@@@@@@@? [email protected]@@@@@    .
.   @@@@@G          [email protected]@@@@:    [email protected]@@@#[email protected]@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@P   ^[email protected]@@@@~.   ^~~~~~^[email protected] @@@@??:~~~~~    .
.   @@@@@B^^^^^^^^. [email protected]@@@@:   [email protected]@@@&^   [email protected][email protected]@@@@@&@@@@@@@@@@@&@J7&@@@@@#.   [email protected]@@@P           [email protected]@@@@?            .
.   @@@@@@@@@@@@@@! [email protected]@@@@:   [email protected]@@@B   ^B&&@@@@@#!#@@@@@@@@@@7G&&@@@@@#!     [email protected]@@@#.           [email protected]@@@@?            .
.   @@@@@@@@@@@@@@! [email protected]@@@@:   [email protected]@@@&^    !YPGPY!  [email protected]@@@@Y&@@@@Y  ~YPGP57.    [email protected]@@@P           [email protected]@@@@?            .
.   @@@@@B~~~~~~~!!.?GPPGP:   [email protected]@@@&7           ?&@@@@P [email protected]@@@@5.          [email protected]@@@&^            [email protected]@@@@?            .
.   @@@@@G          ^~~~~~.    :[email protected]@@@@BY7~^^~75#@@@@@5.    [email protected]@@@@&P?~^^^[email protected]@@@@#~             [email protected]@@@@?            .
.   @@@@@G          [email protected]@@@@:      [email protected]@@@@@@@@@@@@@@@B!!      ^[email protected]@@@@@@@@@@@@@@@&Y               [email protected]@@@@?            .
.   @@@@@G.         [email protected]@@@@:        !YB&@@@@@@@@&BY~           ^JG#@@@@@@@@&#P7.                [email protected]@@@@?            .
.   YYYYY7          !YJJJJ.            :~!7??7!^:                 .^!7??7!~:                   ^YJJJY~            .
.                                                                                                                 .
.                                                                                                                 .
.                                                                                                                 .
.                                  ………………               …………………………………………                  …………………………………………        .
.   PBGGB??                      7&######&5            :B##############&5               .G#################^      .
.   &@@@@5                      [email protected]@@@@@@@@@           :@@@@@@@@@@@@@@@@@G               &@@@@@@@@@@@@ @@@@@^      .
.   PBBBBJ                 !!!!!JPPPPPPPPPY !!!!!     :&@@@@P?JJJJJJJJJJJJJJ?      :JJJJJJJJJJJJJJJJJJJJJJ.       .
.   ~~~~~:                .#@@@@Y          [email protected]@@@@~    :&@@@@7           [email protected]@@&.      ^@@@@.                        .
.   #@@@@Y                .#@@@@[email protected]@@@@~    :&@@@@7   !JJJJJJJJJJJJ?     :JJJJJJJJJJJJJJJJJ!!           .
.   #@@@@Y                .#@@@@@@@@@@@@@@@@@@@@@@~   :&@@@@7   [email protected]@@@@@@@G &@@             @@@@@@@@@@P            .
.   #@@@@Y                .#@@@@&##########&@@@@@~    :&@@@@7   7YYYYYYYYJ???7             JYYYYYYYYYYYYJ???7     .
.   #@@@@Y                .#@@@@5 ........ [email protected]@@@@~    :&@@@@7            [email protected]@@&.                         [email protected]@@#     .
.   #@@@@#5PPPPPPPPPJJ    .#@@@@Y          [email protected]@@@@~    :&@@@@P7??????????JYY5J      .?????????? ???????JYY5J       .
.   &@@@@@@@@@@@@@@@@@    .#@@@@Y          [email protected]@@@@~    :&@@@@@@@@@@@@@@@@@G         ^@@@@@@@@@@@@@@@@@P            .
.   PBBBBBBBBBBBBBBBBY    .#@@@@Y          [email protected]@@@@~    :&@@@@@@@@@@@@@@@@@G         ^@@@@@@@@@@@@@@@ @@5           .
+                                                                                                                 +
+                                                                                                                 +
+ + + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - + + +
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../../standard/erc721a/ERC721A.sol";
import "../../base/common/HootBase.sol";
import "./extensions/HootBaseERC721Owners.sol";

/**
 * @title Hootbirds
 * @author HootLabs
 */
contract HootERC721A is
    HootBase,
    HootBaseERC721Owners,
    ERC721A,
    IERC721Enumerable
{
    using Strings for uint256;

    constructor(string memory name_, string memory symbol_)
        ERC721A(name_, symbol_)
    {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /***********************************|
    |               Config              |
    |__________________________________*/
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /***********************************|
    |               Core                |
    |__________________________________*/

    /**
     * @notice issuer have permission to burn token.
     * @param tokenIds_ list of tokenId
     */
    function burn(uint256[] calldata tokenIds_)
        external
        onlyOwner
        nonReentrant
    {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            uint256 tokenId = tokenIds_[i];
            require(ownerOf(tokenId) == _msgSender(), "caller is not owner");
            _burn(tokenId);
        }
    }

    function totalBurned() external view returns (uint256) {
        return _totalBurned();
    }
    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    /***********************************|
    |        IERC721Enumerable          |
    |__________________________________*/
    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see `_totalMinted`.
     */
    function totalSupply() public view override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return _totalMinted() - _totalBurned();
        }
    }

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        override
        returns (uint256)
    {
        require(owner != address(0), "invalid owner");
        uint256 stopTokenId = _startTokenId() + _totalMinted();
        uint256 scanIndex = 0;
        for (uint256 tokenId = _startTokenId(); tokenId < stopTokenId; tokenId++) {
            if (unsafeOwnerOf(tokenId) != owner) {
                continue;
            }
            if (scanIndex == index) {
                return tokenId;
            }
            ++scanIndex;
        }
        return 0;
    }

    function tokenByIndex(uint256 index) external view override returns (uint256) {
        require(index < _totalMinted(), "out of range");
        return _startTokenId() + index;
    }

    /***********************************|
    |        HootBaseERC721Owners       |
    |__________________________________*/
    function _unsafeOwnerOf(uint256 tokenId_) internal view virtual override returns (address){
        return unsafeOwnerOf(tokenId_);
    }

    /***********************************|
    |               ERC721A             |
    |__________________________________*/
    /**
     * @notice hook function, used to intercept the transfer of token.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        require(!paused(), "token transfer paused");
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }
}

// SPDX-License-Identifier: MIT
/*
+ + + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - + + +
+                                                                                                                 +
+                                                                                                                 +
.                        .^!!~:                                                 .^!!^.                            .
.                            :7Y5Y7^.                                       .^!J5Y7^.                             .
.                              :!5B#GY7^.                             .^!JP##P7:                                  .
.   7777??!         ~????7.        :[email protected]@@@&GY7^.                    .^!JG#@@@@G^        7????????????^ ~????77     .
.   @@@@@G          [email protected]@@@@:       J#@@@@@@@@@@&G57~.          .^7YG#@@@@@@@@@@&5:      #@@@@@@@@@@@@@? [email protected]@@@@@    .
.   @@@@@G          [email protected]@@@@:     :[email protected]@@@@[email protected]@@@@@@@@&B5?~:^7YG#@@@@@@@@[email protected]@@ @@&!!     #@@@@@@@@@@@@@? [email protected]@@@@@    .
.   @@@@@G          [email protected]@@@@:    [email protected]@@@#[email protected]@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@P   ^[email protected]@@@@~.   ^~~~~~^[email protected] @@@@??:~~~~~    .
.   @@@@@B^^^^^^^^. [email protected]@@@@:   [email protected]@@@&^   [email protected][email protected]@@@@@&@@@@@@@@@@@&@J7&@@@@@#.   [email protected]@@@P           [email protected]@@@@?            .
.   @@@@@@@@@@@@@@! [email protected]@@@@:   [email protected]@@@B   ^B&&@@@@@#!#@@@@@@@@@@7G&&@@@@@#!     [email protected]@@@#.           [email protected]@@@@?            .
.   @@@@@@@@@@@@@@! [email protected]@@@@:   [email protected]@@@&^    !YPGPY!  [email protected]@@@@Y&@@@@Y  ~YPGP57.    [email protected]@@@P           [email protected]@@@@?            .
.   @@@@@B~~~~~~~!!.?GPPGP:   [email protected]@@@&7           ?&@@@@P [email protected]@@@@5.          [email protected]@@@&^            [email protected]@@@@?            .
.   @@@@@G          ^~~~~~.    :[email protected]@@@@BY7~^^~75#@@@@@5.    [email protected]@@@@&P?~^^^[email protected]@@@@#~             [email protected]@@@@?            .
.   @@@@@G          [email protected]@@@@:      [email protected]@@@@@@@@@@@@@@@B!!      ^[email protected]@@@@@@@@@@@@@@@&Y               [email protected]@@@@?            .
.   @@@@@G.         [email protected]@@@@:        !YB&@@@@@@@@&BY~           ^JG#@@@@@@@@&#P7.                [email protected]@@@@?            .
.   YYYYY7          !YJJJJ.            :~!7??7!^:                 .^!7??7!~:                   ^YJJJY~            .
.                                                                                                                 .
.                                                                                                                 .
.                                                                                                                 .
.                                  ………………               …………………………………………                  …………………………………………        .
.   PBGGB??                      7&######&5            :B##############&5               .G#################^      .
.   &@@@@5                      [email protected]@@@@@@@@@           :@@@@@@@@@@@@@@@@@G               &@@@@@@@@@@@@ @@@@@^      .
.   PBBBBJ                 !!!!!JPPPPPPPPPY !!!!!     :&@@@@P?JJJJJJJJJJJJJJ?      :JJJJJJJJJJJJJJJJJJJJJJ.       .
.   ~~~~~:                .#@@@@Y          [email protected]@@@@~    :&@@@@7           [email protected]@@&.      ^@@@@.                        .
.   #@@@@Y                .#@@@@[email protected]@@@@~    :&@@@@7   !JJJJJJJJJJJJ?     :JJJJJJJJJJJJJJJJJ!!           .
.   #@@@@Y                .#@@@@@@@@@@@@@@@@@@@@@@~   :&@@@@7   [email protected]@@@@@@@G &@@             @@@@@@@@@@P            .
.   #@@@@Y                .#@@@@&##########&@@@@@~    :&@@@@7   7YYYYYYYYJ???7             JYYYYYYYYYYYYJ???7     .
.   #@@@@Y                .#@@@@5 ........ [email protected]@@@@~    :&@@@@7            [email protected]@@&.                         [email protected]@@#     .
.   #@@@@#5PPPPPPPPPJJ    .#@@@@Y          [email protected]@@@@~    :&@@@@P7??????????JYY5J      .?????????? ???????JYY5J       .
.   &@@@@@@@@@@@@@@@@@    .#@@@@Y          [email protected]@@@@~    :&@@@@@@@@@@@@@@@@@G         ^@@@@@@@@@@@@@@@@@P            .
.   PBBBBBBBBBBBBBBBBY    .#@@@@Y          [email protected]@@@@~    :&@@@@@@@@@@@@@@@@@G         ^@@@@@@@@@@@@@@@ @@5           .
+                                                                                                                 +
+                                                                                                                 +
+ + + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - + + +
*/

pragma solidity ^0.8.0;

/**
 * @title HootBaseERC721Refund
 * @author HootLabs
 */
abstract contract HootBaseERC721Owners {
    /***********************************|
    |               abstract            |
    |__________________________________*/
    function _unsafeOwnerOf(uint256 tokenId_)
        internal
        view
        virtual
        returns (address);

    /***********************************|
    |               Core                |
    |__________________________________*/
    function exists(uint256 tokenId_) public view virtual returns (bool) {
        return _unsafeOwnerOf(tokenId_) != address(0);
    }

    function ownersOf(uint256[] calldata tokenIDs_)
        external
        view
        virtual
        returns (address[] memory)
    {
        address[] memory owners = new address[](tokenIDs_.length);
        for (uint256 i = 0; i < tokenIDs_.length; ++i) {
            owners[i] = _unsafeOwnerOf(tokenIDs_[i]);
        }
        return owners;
    }
}

// SPDX-License-Identifier: MIT
/*
+ + + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - + + +
+                                                                                                                 +
+                                                                                                                 +
.                        .^!!~:                                                 .^!!^.                            .
.                            :7Y5Y7^.                                       .^!J5Y7^.                             .
.                              :!5B#GY7^.                             .^!JP##P7:                                  .
.   7777??!         ~????7.        :[email protected]@@@&GY7^.                    .^!JG#@@@@G^        7????????????^ ~????77     .
.   @@@@@G          [email protected]@@@@:       J#@@@@@@@@@@&G57~.          .^7YG#@@@@@@@@@@&5:      #@@@@@@@@@@@@@? [email protected]@@@@@    .
.   @@@@@G          [email protected]@@@@:     :[email protected]@@@@[email protected]@@@@@@@@&B5?~:^7YG#@@@@@@@@[email protected]@@ @@&!!     #@@@@@@@@@@@@@? [email protected]@@@@@    .
.   @@@@@G          [email protected]@@@@:    [email protected]@@@#[email protected]@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@P   ^[email protected]@@@@~.   ^~~~~~^[email protected] @@@@??:~~~~~    .
.   @@@@@B^^^^^^^^. [email protected]@@@@:   [email protected]@@@&^   [email protected][email protected]@@@@@&@@@@@@@@@@@&@J7&@@@@@#.   [email protected]@@@P           [email protected]@@@@?            .
.   @@@@@@@@@@@@@@! [email protected]@@@@:   [email protected]@@@B   ^B&&@@@@@#!#@@@@@@@@@@7G&&@@@@@#!     [email protected]@@@#.           [email protected]@@@@?            .
.   @@@@@@@@@@@@@@! [email protected]@@@@:   [email protected]@@@&^    !YPGPY!  [email protected]@@@@Y&@@@@Y  ~YPGP57.    [email protected]@@@P           [email protected]@@@@?            .
.   @@@@@B~~~~~~~!!.?GPPGP:   [email protected]@@@&7           ?&@@@@P [email protected]@@@@5.          [email protected]@@@&^            [email protected]@@@@?            .
.   @@@@@G          ^~~~~~.    :[email protected]@@@@BY7~^^~75#@@@@@5.    [email protected]@@@@&P?~^^^[email protected]@@@@#~             [email protected]@@@@?            .
.   @@@@@G          [email protected]@@@@:      [email protected]@@@@@@@@@@@@@@@B!!      ^[email protected]@@@@@@@@@@@@@@@&Y               [email protected]@@@@?            .
.   @@@@@G.         [email protected]@@@@:        !YB&@@@@@@@@&BY~           ^JG#@@@@@@@@&#P7.                [email protected]@@@@?            .
.   YYYYY7          !YJJJJ.            :~!7??7!^:                 .^!7??7!~:                   ^YJJJY~            .
.                                                                                                                 .
.                                                                                                                 .
.                                                                                                                 .
.                                  ………………               …………………………………………                  …………………………………………        .
.   PBGGB??                      7&######&5            :B##############&5               .G#################^      .
.   &@@@@5                      [email protected]@@@@@@@@@           :@@@@@@@@@@@@@@@@@G               &@@@@@@@@@@@@ @@@@@^      .
.   PBBBBJ                 !!!!!JPPPPPPPPPY !!!!!     :&@@@@P?JJJJJJJJJJJJJJ?      :JJJJJJJJJJJJJJJJJJJJJJ.       .
.   ~~~~~:                .#@@@@Y          [email protected]@@@@~    :&@@@@7           [email protected]@@&.      ^@@@@.                        .
.   #@@@@Y                .#@@@@[email protected]@@@@~    :&@@@@7   !JJJJJJJJJJJJ?     :JJJJJJJJJJJJJJJJJ!!           .
.   #@@@@Y                .#@@@@@@@@@@@@@@@@@@@@@@~   :&@@@@7   [email protected]@@@@@@@G &@@             @@@@@@@@@@P            .
.   #@@@@Y                .#@@@@&##########&@@@@@~    :&@@@@7   7YYYYYYYYJ???7             JYYYYYYYYYYYYJ???7     .
.   #@@@@Y                .#@@@@5 ........ [email protected]@@@@~    :&@@@@7            [email protected]@@&.                         [email protected]@@#     .
.   #@@@@#5PPPPPPPPPJJ    .#@@@@Y          [email protected]@@@@~    :&@@@@P7??????????JYY5J      .?????????? ???????JYY5J       .
.   &@@@@@@@@@@@@@@@@@    .#@@@@Y          [email protected]@@@@~    :&@@@@@@@@@@@@@@@@@G         ^@@@@@@@@@@@@@@@@@P            .
.   PBBBBBBBBBBBBBBBBY    .#@@@@Y          [email protected]@@@@~    :&@@@@@@@@@@@@@@@@@G         ^@@@@@@@@@@@@@@@ @@5           .
+                                                                                                                 +
+                                                                                                                 +
+ + + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - + + +
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

contract HootBase is ReentrancyGuard, Pausable, Ownable {
    event PermissionChanged(address indexed addr, uint8 permission);

    event Deposit(address indexed account, uint256 amount);
    event Withdraw(address indexed account, uint256 amount);
    event ContractParsed();
    event ContractUnparsed();
    event ContractSealed();

    uint8 public constant NO_PERMISSION = 0;
    uint8 public constant MANAGER = 1;
    uint8 public constant MAINTAINER = 2;
    uint8 public constant OPERATOR = 3;

    mapping(address => uint8) private _permissions;
    address[] maintainers;

    bool public contractSealed = false;

    /***********************************|
    |               Config              |
    |__________________________________*/
    /**
     * @notice setManagerAddress is used to allow the issuer to modify the maintainerAddress
     */
    function setPermission(address address_, uint8 permission_)
        external
        onlyOwner
    {
        if (permission_ == NO_PERMISSION) {
            delete _permissions[address_];
        } else {
            _permissions[address_] = permission_;
        }

        emit PermissionChanged(address_, permission_);
    }

    function getPermissions()
        external
        view
        atLeastManager
        returns (address[] memory, uint8[] memory)
    {
        uint8[] memory permissions = new uint8[](maintainers.length);
        unchecked {
            for (uint256 i = 0; i < maintainers.length; i++) {
                permissions[i] = _permissions[maintainers[i]];
            }
        }
        return (maintainers, permissions);
    }

    function getPermission(address address_) external view returns (uint8) {
        return _permissions[address_];
    }

    /***********************************|
    |               Core                |
    |__________________________________*/
    /**
     * @notice issuer deposit ETH into the contract. only issuer have permission
     */
    function deposit() external payable atLeastMaintainer nonReentrant {
        emit Deposit(_msgSender(), msg.value);
    }

    /**
     * issuer withdraws the ETH temporarily stored in the contract through this method.
     */
    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
        emit Withdraw(_msgSender(), balance);
    }

    /***********************************|
    |               Basic               |
    |__________________________________*/
    /**
     * @notice for the purpose of protecting user assets, under extreme conditions,
     * the circulation of all tokens in the contract needs to be frozen.
     * This process is under the supervision of the community.
     */
    function emergencyPause() external atLeastManager notSealed {
        _pause();
        emit ContractParsed();
    }

    /**
     * @notice unpause the contract
     */
    function unpause() external atLeastManager notSealed {
        _unpause();
        emit ContractUnparsed();
    }

    /**
     * @notice when the project is stable enough, the issuer will call sealContract
     * to give up the permission to call emergencyPause and unpause.
     */
    function sealContract() external onlyOwner {
        contractSealed = true;
        emit ContractSealed();
    }

    /***********************************|
    |               Modifier            |
    |__________________________________*/
    /**
     * @notice only owner or manager has the permission to call this method
     */
    modifier atLeastManager() {
        uint8 permission = _permissions[_msgSender()];
        require(
            owner() == _msgSender() || permission == MANAGER,
            "not authorized"
        );
        _;
    }
    /**
     * @notice only owner, manager or maintainer has the permission to call this method
     */
    modifier atLeastMaintainer() {
        uint8 permission = _permissions[_msgSender()];
        require(
            owner() == _msgSender() ||
                permission == MAINTAINER ||
                permission == MANAGER,
            "not authorized"
        );
        _;
    }
    /**
     * @notice only owner, manager or maintainer or operator has the permission to call this method
     */
    modifier atLeastOperator() {
        uint8 permission = _permissions[_msgSender()];
        require(
            owner() == _msgSender() ||
                permission == MAINTAINER ||
                permission == MANAGER ||
                permission == OPERATOR,
            "not authorized"
        );
        _;
    }

    /**
     * @notice for security reasons, CA is not allowed to call sensitive methods.
     */
    modifier callerIsUser() {
        require(tx.origin == _msgSender(), "caller is another contract");
        _;
    }

    /**
     * @notice function call is only allowed when the contract has not been sealed
     */
    modifier notSealed() {
        require(!contractSealed, "contract sealed");
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.0.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./IERC721Extra.sol";

/**
 * @dev ERC721 token receiver interface.
 */
interface ERC721A__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is Context, ERC165, IERC721, IERC721Metadata, IERC721Extra {
    // Mask of an entry in packed address data.
    uint256 private constant BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 private constant BITPOS_NUMBER_MINTED = 64;

    // The bit position of `numberBurned` in packed address data.
    uint256 private constant BITPOS_NUMBER_BURNED = 128;

    // The bit position of `aux` in packed address data.
    uint256 private constant BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    uint256 private constant BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 private constant BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 private constant BITMASK_BURNED = 1 << 224;
    
    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 private constant BITPOS_NEXT_INITIALIZED = 225;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 private constant BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The tokenId of the next token to be minted.
    uint256 private _currentIndex;

    // The number of tokens burned.
    uint256 private _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned.
    // See `_packedOwnershipOf` implementation for details.
    //
    // Bits Layout:
    // - [0..159]   `addr`
    // - [160..223] `startTimestamp`
    // - [224]      `burned`
    // - [225]      `nextInitialized`
    mapping(uint256 => uint256) private _packedOwnerships;

    // Mapping owner address to address data.
    //
    // Bits Layout:
    // - [0..63]    `balance`
    // - [64..127]  `numberMinted`
    // - [128..191] `numberBurned`
    // - [192..255] `aux`
    mapping(address => uint256) private _packedAddressData;

    // Mapping from token ID to approved address.
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    /**
     * @dev Returns the starting token ID. 
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Returns the next token ID to be minted.
     */
    function _nextTokenId() internal view returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to `_startTokenId()`
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view returns (uint256) {
        return _burnCounter;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        // The interface IDs are constants representing the first 4 bytes of the XOR of
        // all function selectors in the interface. See: https://eips.ethereum.org/EIPS/eip-165
        // e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _packedAddressData[owner] & BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> BITPOS_NUMBER_MINTED) & BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> BITPOS_NUMBER_BURNED) & BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> BITPOS_AUX);
    }

    /**
     * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        uint256 packed = _packedAddressData[owner];
        uint256 auxCasted;
        assembly { // Cast aux without masking.
            auxCasted := aux
        }
        packed = (packed & BITMASK_AUX_COMPLEMENT) | (auxCasted << BITPOS_AUX);
        _packedAddressData[owner] = packed;
    }

    /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _unsafePackedOwnershipOf(uint256 tokenId) private view returns (uint256) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr)
                if (curr < _currentIndex) {
                    uint256 packed = _packedOwnerships[curr];
                    // If not burned.
                    if (packed & BITMASK_BURNED == 0) {
                        // Invariant:
                        // There will always be an ownership that has an address and is not burned
                        // before an ownership that does not have an address and is not burned.
                        // Hence, curr will not underflow.
                        //
                        // We can directly compare the packed value.
                        // If the address is zero, packed is zero.
                        while (packed == 0) {
                            packed = _packedOwnerships[--curr];
                        }
                        return packed;
                    }
                }
        }
        return 0;
    }
    /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256) {
        uint256 packed = _unsafePackedOwnershipOf(tokenId);
        if(packed == 0){
            revert OwnerQueryForNonexistentToken();
        }
        return packed;
    }

    /**
     * Returns the unpacked `TokenOwnership` struct from `packed`.
     */
    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> BITPOS_START_TIMESTAMP);
        ownership.burned = packed & BITMASK_BURNED != 0;
    }

    /**
     * Returns the unpacked `TokenOwnership` struct at `index`.
     */
    function _ownershipAt(uint256 index) internal view returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnerships[index]);
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal {
        if (_packedOwnerships[index] == 0) {
            _packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }
    function unsafeOwnerOf(uint256 tokenId) public view virtual returns (address) {
        return address(uint160(_unsafePackedOwnershipOf(tokenId)));
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev Casts the address to uint256 without masking.
     */
    function _addressToUint256(address value) private pure returns (uint256 result) {
        assembly {
            result := value
        }
    }

    /**
     * @dev Casts the boolean to uint256 without branching.
     */
    function _boolToUint256(bool value) private pure returns (uint256 result) {
        assembly {
            result := value
        }
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = address(uint160(_packedOwnershipOf(tokenId)));
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSenderERC721A()) revert ApproveToCaller();

        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        _transfer(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return
            _startTokenId() <= tokenId &&
            tokenId < _currentIndex && // If within bounds,
            _packedOwnerships[tokenId] & BITMASK_BURNED == 0; // and not burned.
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     *   {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the balance and number minted.
            _packedAddressData[to] += quantity * ((1 << BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] =
                _addressToUint256(to) |
                (block.timestamp << BITPOS_START_TIMESTAMP) |
                (_boolToUint256(quantity == 1) << BITPOS_NEXT_INITIALIZED);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            if (to.code.length != 0) {
                do {
                    emit Transfer(address(0), to, updatedIndex);
                    if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (updatedIndex < end);
                // Reentrancy protection
                if (_currentIndex != startTokenId) revert();
            } else {
                do {
                    emit Transfer(address(0), to, updatedIndex++);
                } while (updatedIndex < end);
            }
            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 quantity) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the balance and number minted.
            _packedAddressData[to] += quantity * ((1 << BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] =
                _addressToUint256(to) |
                (block.timestamp << BITPOS_START_TIMESTAMP) |
                (_boolToUint256(quantity == 1) << BITPOS_NEXT_INITIALIZED);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            do {
                emit Transfer(address(0), to, updatedIndex++);
            } while (updatedIndex < end);

            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        if (address(uint160(prevOwnershipPacked)) != from) revert TransferFromIncorrectOwner();

        bool isApprovedOrOwner = (_msgSenderERC721A() == from ||
            isApprovedForAll(from, _msgSenderERC721A()) ||
            getApproved(tokenId) == _msgSenderERC721A());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        delete _tokenApprovals[tokenId];

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            // We can directly increment and decrement the balances.
            --_packedAddressData[from]; // Updates: `balance -= 1`.
            ++_packedAddressData[to]; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] =
                _addressToUint256(to) |
                (block.timestamp << BITPOS_START_TIMESTAMP) |
                BITMASK_NEXT_INITIALIZED;

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        address from = address(uint160(prevOwnershipPacked));

        if (approvalCheck) {
            bool isApprovedOrOwner = (_msgSenderERC721A() == from ||
                isApprovedForAll(from, _msgSenderERC721A()) ||
                getApproved(tokenId) == _msgSenderERC721A());

            if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner.
        delete _tokenApprovals[tokenId];

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            // Updates:
            // - `balance -= 1`.
            // - `numberBurned += 1`.
            //
            // We can directly decrement the balance, and increment the number burned.
            // This is equivalent to `packed -= 1; packed += 1 << BITPOS_NUMBER_BURNED;`.
            _packedAddressData[from] += (1 << BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - `address` to the last owner.
            // - `startTimestamp` to the timestamp of burning.
            // - `burned` to `true`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] =
                _addressToUint256(from) |
                (block.timestamp << BITPOS_START_TIMESTAMP) |
                BITMASK_BURNED | 
                BITMASK_NEXT_INITIALIZED;

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try ERC721A__IERC721Receiver(to).onERC721Received(_msgSenderERC721A(), from, tokenId, _data) returns (
            bytes4 retval
        ) {
            return retval == ERC721A__IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function _toString(uint256 value) internal pure returns (string memory ptr) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), 
            // but we allocate 128 bytes to keep the free memory pointer 32-byte word aliged.
            // We will need 1 32-byte word to store the length, 
            // and 3 32-byte words to store a maximum of 78 digits. Total: 32 + 3 * 32 = 128.
            ptr := add(mload(0x40), 128)
            // Update the free memory pointer to allocate.
            mstore(0x40, ptr)

            // Cache the end of the memory to calculate the length later.
            let end := ptr

            // We write the string from the rightmost digit to the leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // Costs a bit more than early returning for the zero case,
            // but cheaper in terms of deployment and overall runtime costs.
            for { 
                // Initialize and perform the first pass without check.
                let temp := value
                // Move the pointer 1 byte leftwards to point to an empty character slot.
                ptr := sub(ptr, 1)
                // Write the character to the pointer. 48 is the ASCII index of '0'.
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
            } temp { 
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
            } { // Body of the for loop.
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
            }
            
            let length := sub(end, ptr)
            // Move the pointer 32 bytes leftwards to make room for the length.
            ptr := sub(ptr, 32)
            // Store the length.
            mstore(ptr, length)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.0.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of an ERC721A compliant contract.
 */
interface IERC721Extra {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * The caller cannot approve to the current owner.
     */
    error ApprovalToCurrentOwner();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
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
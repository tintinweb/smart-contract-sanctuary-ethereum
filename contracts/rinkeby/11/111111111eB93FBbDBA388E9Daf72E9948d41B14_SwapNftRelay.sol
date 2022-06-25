// SPDX-License-Identifier: LicenseRef-Blockwell-Smart-License
pragma solidity ^0.8.9;

import "common8/LicenseRef-Blockwell-Smart-License.sol";
import "common8/relay/RelayBase.sol";
import "common8/ERC721.sol";
import "common8/Erc20.sol";
import "common8/ERC721TokenReceiver.sol";

/**
 * @dev Relay contract for verifying crosschain swaps.
 *
 * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
 */
contract SwapNftRelay is RelayBase, ERC721TokenReceiver {
    uint256 public swapNonce;

    event SwapToChain(
        uint256 toChainId,
        uint256 swapNonce,
        ERC721 tokenContract,
        address indexed from,
        address indexed to,
        bytes32 indexed swapId,
        uint256[] tokenIds
    );

    event SwapFromChain(
        ERC721 tokenContract,
        address indexed from,
        address indexed to,
        bytes32 indexed swapId,
        uint256 fromChainId,
        uint256[] tokenIds
    );

    error SwapIdMismatch();

    constructor(uint256 _swappersNeeded) RelayBase(_swappersNeeded) {
        name = "NFT SwapRelay";
        bwtype = SWAP_NFT_RELAY;
        bwver = 88;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    /**
     * @dev Initiates a swap to another chain. Transfers the tokens to this contract and emits an event
     *      indicating the request to swap.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function swapToChain(
        ERC721 tokenContract,
        uint256 toChainId,
        address to,
        uint256[] calldata tokenIds
    ) public {
        uint256 nonce = getSwapNonce();
        uint256 chainID;
        assembly {
            chainID := chainid()
        }

        bytes32 swapId = keccak256(
            abi.encodePacked(
                address(this),
                chainID,
                nonce,
                tokenContract,
                msg.sender,
                to,
                toChainId,
                tokenIds
            )
        );

        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenContract.transferFrom(msg.sender, address(this), tokenIds[i]);
        }

        emit SwapToChain(toChainId, nonce, tokenContract, msg.sender, to, swapId, tokenIds);
    }

    function swapFromChain(
        address relayContract,
        uint256 fromChainId,
        uint256 sourceSwapNonce,
        address sourceTokenContract,
        ERC721 tokenContract,
        address from,
        address to,
        bytes32 swapId,
        uint256[] calldata tokenIds
    ) public onlySwapper {
        uint256 chainID;
        assembly {
            chainID := chainid()
        }
        bytes32 swapIdCheck = keccak256(
            abi.encodePacked(
                relayContract,
                fromChainId,
                sourceSwapNonce,
                sourceTokenContract,
                from,
                to,
                chainID,
                tokenIds
            )
        );
        if (swapId != swapIdCheck) {
            revert SwapIdMismatch();
        }

        if (shouldSwap(swapId, msg.sender)) {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                tokenContract.transferFrom(address(this), to, tokenIds[i]);
            }
        }

        emit SwapFromChain(tokenContract, from, to, swapId, fromChainId, tokenIds);
    }

    function getSwapNonce() internal returns (uint256) {
        return ++swapNonce;
    }

    function withdraw() public onlyAdmin {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawTokens(Erc20 token) public onlyAdmin {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: LicenseRef-Blockwell-Smart-License
/*

BLOCKWELL SMART LICENSE

Everyone is permitted to copy and distribute verbatim copies of this license
document, but changing it is not allowed.


PREAMBLE

Blockwell provides a blockchain platform designed to make cryptocurrency fast,
easy and low cost. It enables anyone to tokenize, monetize, analyze and scale
their business with blockchain. Users who deploy smart contracts on
Blockwell’s blockchain agree to do so on the terms and conditions of this
Blockwell Smart License, unless otherwise expressly agreed in writing with
Blockwell.

The Blockwell Smart License is an evolved version of GNU General Public
License version 2. The extent of the modification is to reflect Blockwell’s
intention to require its users to send a minting and system transfer fee to
the Blockwell network each time a smart contract is deployed (or token is
created). These fees will then be distributed among Blockwell token holders
and to contributors that build and support the Blockwell ecosystem.

You can create a token on the Blockwell network at:
https://app.blockwell.ai/prime

The accompanying source code can be used in accordance with the terms of this
License, using the following arguments, with the bracketed arguments being
contractually mandated by this license:

tokenName, tokenSymbol, tokenDecimals, tokenSupply, founderWallet,
[0xda0f00d92086E50099742B6bfB0230c942DdA4cC],
[0xda0f00d92086E50099742B6bfB0230c942DdA4cC], [20], attorneyWallet,
attorneyAndLegalEmailAddress

The precise terms and conditions for copying, distribution, deployment and
modification follow.


TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION, DEPLOYMENT AND MODIFICATION

0. This License applies to any program or other work which contains a notice
   placed by the copyright holder saying it may be distributed under the terms
   of this License. The "Program", below, refers to any such program or work,
   and a "work based on the Program" means either the Program or any
   derivative work under copyright law: that is to say, a work containing the
   Program or a portion of it, either verbatim or with modifications and/or
   translated into another language. (Hereinafter, translation is included
   without limitation in the term "modification".) Each licensee is addressed
   as "you".

   Activities other than copying, distribution, deployment and modification are
   not covered by this License; they are outside its scope. The act of running
   the Program is not restricted, and the output from the Program is covered only
   if its contents constitute a work based on the Program (independent of having
   been made by running the Program). Whether that is true depends on what the
   Program does.

1. You may copy and distribute verbatim copies of the Program's source code as
   you receive it, in any medium, provided that you conspicuously and
   appropriately publish on each copy an appropriate copyright notice and
   disclaimer of warranty; keep intact all the notices that refer to this
   License and to the absence of any warranty; and give any other recipients
   of the Program a copy of this License along with the Program.

   You may charge a fee for the physical act of transferring a copy, and you may
   at your option offer warranty protection in exchange for a fee.

2. You may modify your copy or copies of the Program or any portion of it,
   thus forming a work based on the Program, and copy and distribute such
   modifications or work under the terms of Section 1 above, provided that you
   also meet all of these conditions:

a) You must cause the modified files to carry prominent notices stating that
   you changed the files.

b) You must cause any work that you distribute or publish, that in whole or in
   part contains or is derived from the Program or any part thereof, to be
   licensed as a whole to all third parties under the terms of this License.

c) You must cause Blockwell Fee Wallet
   “0xda0f00d92086E50099742B6bfB0230c942DdA4cC” to receive 2% of the total
   supply of tokens each and every any time tokens are created on the
   Blockchain network. This can be achieved using the current version of the
   source code to which this License attaches by setting the “feeAccount”
   parameter to Blockwell Fee Wallet
   “0xda0f00d92086E50099742B6bfB0230c942DdA4cC”, and the “feePercentageTenths”
   parameter to “20” when deploying.

d) You must add Blockwell’s wallet
   “0xda0f00d92086E50099742B6bfB0230c942DdA4cC” as a BW Admin, and you must
   not restrict the abilities of a BW Admin in any derivative works. This can
   be achieved using the current version of the source code to which this
   License attaches by setting the “bwAdmin” parameter to Blockwell’s wallet
   “0xda0f00d92086E50099742B6bfB0230c942DdA4cC” when deploying.

   These requirements apply to the modified work as a whole. If identifiable
   sections of that work are not derived from the Program, and can be reasonably
   considered independent and separate works in themselves, then this License,
   and its terms, do not apply to those sections when you distribute them as
   separate works. But when you distribute the same sections as part of a whole
   which is a work based on the Program, the distribution of the whole must be on
   the terms of this License, whose permissions for other licensees extend to the
   entire whole, and thus to each and every part regardless of who wrote it.

   Thus, it is not the intent of this section to claim rights or contest your
   rights to work written entirely by you; rather, the intent is to exercise the
   right to control the distribution of derivative or collective works based on
   the Program.

   In addition, mere aggregation of another work not based on the Program with
   the Program (or with a work based on the Program) on a volume of a storage or
   distribution medium does not bring the other work under the scope of this
   License.

3. You may copy and distribute the Program (or a work based on it, under
   Section 2) in object code or executable form under the terms of Sections 1
   and 2 above provided that you also make good faith and reasonable attempts
   to make available the complete corresponding machine-readable source code,
   which must be distributed under the terms of Sections 1 and 2 above.

   The source code for a work means the preferred form of the work for making
   modifications to it. For an executable work, complete source code means all
   the source code for all modules it contains, plus any associated interface
   definition files, plus the scripts used to control compilation and
   installation of the executable. However, as a special exception, the source
   code distributed need not include anything that is normally distributed (in
   either source or binary form) with the major components (compiler, kernel, and
   so on) of the operating system on which the executable runs, unless that
   component itself accompanies the executable.

   If distribution of executable or object code is made by offering access to
   copy from a designated place, then offering equivalent access to copy the
   source code from the same place counts as distribution of the source code,
   even though third parties are not compelled to copy the source along with the
   object code.

   Distribution and execution of executable or object code as part of existing
   smart contracts on the blockchain in the normal operation of the blockchain
   network (miners, node hosts, infrastructure providers and so on) is excepted
   from the requirement to make available the source code as set out in this
   clause.

4. You may not copy, modify, sublicense, or distribute the Program except as
   expressly provided under this License. Any attempt otherwise to copy,
   modify, sublicense or distribute the Program is void, and will
   automatically terminate your rights under this License. However, parties
   who have received copies, or rights, from you under this License will not
   have their licenses terminated so long as such parties remain in full
   compliance.

5. You are not required to accept this License, since you have not signed it.
   However, nothing else grants you permission to modify or distribute the
   Program or its derivative works. These actions are prohibited by law if you
   do not accept this License. Therefore, by modifying or distributing the
   Program (or any work based on the Program), you indicate your acceptance of
   this License to do so, and all its terms and conditions for copying,
   distributing or modifying the Program or works based on it.

6. Each time you redistribute the Program (or any work based on the Program),
   the recipient automatically receives a license from the original licensor
   to copy, distribute or modify the Program subject to these terms and
   conditions. You may not impose any further restrictions on the recipients'
   exercise of the rights granted herein. You are not responsible for
   enforcing compliance by third parties to this License.

7. If, as a consequence of a court judgment or allegation of patent
   infringement or for any other reason (not limited to patent issues),
   conditions are imposed on you (whether by court order, agreement or
   otherwise) that contradict the conditions of this License, they do not
   excuse you from the conditions of this License. If you cannot distribute so
   as to satisfy simultaneously your obligations under this License and any
   other pertinent obligations, then as a consequence you may not distribute
   the Program at all. For example, if a patent license would not permit
   royalty-free redistribution of the Program by all those who receive copies
   directly or indirectly through you, then the only way you could satisfy
   both it and this License would be to refrain entirely from distribution of
   the Program.

   If any portion of this section is held invalid or unenforceable under any
   particular circumstance, the balance of the section is intended to apply and
   the section as a whole is intended to apply in other circumstances.

   It is not the purpose of this section to induce you to infringe any patents or
   other property right claims or to contest validity of any such claims; this
   section has the sole purpose of protecting the integrity of the free software
   distribution system, which is implemented by public license practices. Many
   people have made generous contributions to the wide range of software
   distributed through that system in reliance on consistent application of that
   system; it is up to the author/donor to decide if he or she is willing to
   distribute software through any other system and a licensee cannot impose that
   choice.

   This section is intended to make thoroughly clear what is believed to be a
   consequence of the rest of this License.

8. Blockwell may publish revised and/or new versions of the Blockwell Smart
   License from time to time. Such new versions will be similar in spirit to
   the present version, but may differ in detail to address new problems or
   concerns.


NO WARRANTY

9. THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE
   LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR
   OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY OF ANY KIND,
   EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
   WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
   ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM AND YOUR USE
   OF THE SOURCE CODE INCLUDING AS TO ITS COMPLIANCE WITH ANY APPLICABLE LAW
   IS WITH YOU. SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
   NECESSARY SERVICING, REPAIR OR CORRECTION.

10. IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL
    ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
    REDISTRIBUTE THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES,
    INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES
    ARISING OUT OF THE USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT
    LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES
    SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE
    WITH ANY OTHER PROGRAMS), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN
    ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

END OF TERMS AND CONDITIONS

*/

pragma solidity >=0.8.0;

contract NoContract {

}

// SPDX-License-Identifier: LicenseRef-Blockwell-Smart-License
pragma solidity ^0.8.9;

import "./ContractGroups.sol";
import "common/Type.sol";

/**
 * @dev Relay contract for verifying crosschain swaps.
 *
 * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
 */
contract RelayBase is ContractGroups, Type {
    struct SwapData {
        bool swapped;
        address[] swappers;
    }

    string public name = "SwapRelay";

    uint256 public swappersNeeded;

    mapping(bytes32 => bool) public swapDone;

    mapping(bytes32 => address[]) internal swaps;

    event Swap(bytes32 indexed swapId, address indexed swapper, uint256 indexed count);
    event SwappersNeededUpdate(uint256 indexed count);

    constructor(uint256 _swappersNeeded) {
        swappersNeeded = _swappersNeeded;
        _addAdmin(msg.sender);

        bwtype = SWAP_RELAY;
        bwver = 85;
    }

    function setSwappersNeeded(uint256 count) public onlyAdmin {
        expect(count > 0, ERROR_BAD_PARAMETER_1);
        swappersNeeded = count;
        emit SwappersNeededUpdate(count);
    }

    function swapsDone(bytes32[] calldata swapIds) public view returns (bool[] memory) {
        bool[] memory done = new bool[](swapIds.length);

        for (uint256 i = 0; i < swapIds.length; i++) {
            done[i] = swapDone[swapIds[i]];
        }

        return done;
    }

    function swapRelayers(bytes32 swapId) public view returns (address[] memory) {
        return swaps[swapId];
    }

    function shouldSwap(bytes32 swapId, address swapper) internal returns (bool) {
        if (swapDone[swapId]) {
            return false;
        }
        address[] storage swappers = swaps[swapId];

        for (uint256 i = 0; i < swappers.length; i++) {
            if (swappers[i] == swapper) {
                return false;
            }
        }

        emit Swap(swapId, swapper, swappers.length + 1);
        if (swappers.length + 1 >= swappersNeeded) {
            swapDone[swapId] = true;
            if (swappers.length > 0) {
                delete swaps[swapId];
            }
            return true;
        }

        swappers.push(swapper);

        return false;
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.6;

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
interface ERC721 /* is ERC165 */ {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.8.0;

interface Erc20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.6;

interface ERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) external returns (bytes4);
}

// SPDX-License-Identifier: LicenseRef-Blockwell-Smart-License
pragma solidity ^0.8.9;

import "common/ErrorCodes.sol";
import "../Groups.sol";

/**
 * @dev User groups for SwapRelay.
 *
 * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
 */
contract ContractGroups is ErrorCodes {
    uint8 public constant ADMIN = 1;
    uint8 public constant SWAPPERS = 7;

    using Groups for Groups.GroupMap;

    Groups.GroupMap groups;

    event AddedToGroup(uint8 indexed groupId, address indexed account);
    event RemovedFromGroup(uint8 indexed groupId, address indexed account);


    modifier onlyAdmin() {
        expect(isAdmin(msg.sender), ERROR_UNAUTHORIZED);
        _;
    }
    // ADMIN

    function _addAdmin(address account) internal {
        _add(ADMIN, account);
    }

    function addAdmin(address account) public onlyAdmin {
        _addAdmin(account);
    }

    function removeAdmin(address account) public onlyAdmin {
        _remove(ADMIN, account);
    }

    function isAdmin(address account) public view returns (bool) {
        return _contains(ADMIN, account);
    }

    // SWAPPERS

    function addSwapper(address account) public onlyAdmin {
        _addSwapper(account);
    }

    function _addSwapper(address account) internal {
        _add(SWAPPERS, account);
    }

    function removeSwapper(address account) public onlyAdmin {
        _remove(SWAPPERS, account);
    }

    function isSwapper(address account) public view returns (bool) {
        return _contains(SWAPPERS, account);
    }

    modifier onlySwapper() {
        expect(isSwapper(msg.sender), ERROR_UNAUTHORIZED);
        _;
    }

    // Internal functions

    function _add(uint8 groupId, address account) internal {
        groups.add(groupId, account);
        emit AddedToGroup(groupId, account);
    }

    function _remove(uint8 groupId, address account) internal {
        groups.remove(groupId, account);
        emit RemovedFromGroup(groupId, account);
    }

    function _contains(uint8 groupId, address account) internal view returns (bool) {
        return groups.contains(groupId, account);
    }
}

// SPDX-License-Identifier: LicenseRef-Blockwell-Smart-License
pragma solidity >=0.4.25;

/**
 * @dev Contract type mapping.
 *
 * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
 */
contract Type {
    uint256 constant PRIME = 1; // Prime/master/build/PrimeToken.abi happ=suggestions features=erc20,suggestions
    uint256 constant PRIDE = 2; // Pride/build/PrideToken.abi features=erc20
    uint256 constant FOOD_COIN = 3; // Prime/foodcoin/build/FoodCoin.abi features=erc20
    uint256 constant EGO = 4; // OldEgoCoin/master/build/EgoCoin.abi happ=suggestions features=erc20
    uint256 constant EGO_TIME_BASED = 5;  // OldEgoCoin/time-based/build/EgoCoin.abi happ=suggestions features=erc20
    uint256 constant EGO_TRAINER_TOKEN = 6;  // OldEgoCoin/trainer-token/build/TrainerToken.abi features=erc20
    uint256 constant DAICO = 7; // Daico/build/Daico.abi happ=daico features=daico
    uint256 constant ITEM_DROPS = 8; // ItemDrops/build/ItemDrops.abi happ=lotto features=lotto
    uint256 constant ITEM_TOKEN = 9; // ItemDrops/build/ItemToken.abi features=erc20
    uint256 constant COMMUNITY = 10; // Community/build/CommunityToken.abi happ=suggestions features=erc20,suggestions,proposals
    uint256 constant PAYMENT_RELAY = 11; // PaymentRelay/build/PaymentRelay.abi
    uint256 constant GHOST = 12; // Ghost/build/GhostToken.abi features=erc20
    uint256 constant FORUM = 13;  // Forum/build/ForumToken.abi happ=nft features=erc721,suggestions,proposals
    uint256 constant BOOK = 14;  //Book/build/BaseBook.abi happ=book features=book
    uint256 constant VOTING_BOOK = 15;  //Book/build/VotingBook.abi happ=book
    uint256 constant REFUNDS = 16;  //Refund/build/Refunds.abi happ=refunds features=refunds
    uint256 constant SMART_LICENSE = 17;  //SmartLicense/build/SmartLicense.abi happ=smart features=smart-license
    uint256 constant FIRE = 18;  //OldFire/standard/build/FireToken.abi features=erc20
    uint256 constant CORE = 19;  //Core/build/CoreToken.abi happ=core features=erc20,suggestions,core
    uint256 constant CORE_TASKS_EXTENSION = 20;  //Core/build/TasksExtension.abi happ=core
    uint256 constant PRICES = 21;  //Prices/build/Prices.abi
    uint256 constant CORE_TASKS_LIBRARY = 22; //Core/build/TasksLibrary.abi
    uint256 constant CORE_FREELANCE_EXTENSION = 23; //Core/build/FreelanceExtension.abi happ=core
    uint256 constant CORE_FREELANCE_LIBRARY = 24; //Core/build/FreelanceLibrary.abi
    uint256 constant HOURGLASS = 25; //Hourglass/build/Hourglass.abi happ=hourglass features=erc20,hourglass
    uint256 constant NFT = 26; //Nft/build/NfToken.abi happ=nft features=erc721
    uint256 constant PARTIAL_NFT = 27; //Nft/build/PartialNft.abi happ=nft features=erc721
    uint256 constant FUEL = 28; //Fuel/build/FuelToken.abi features=erc20,stake
    uint256 constant SWAPPER = 29; //Swapper/build/Swapper.abi features=swapper
    uint256 constant SWAP_RELAY = 30; //Prime/master/build/SwapRelay.abi
    uint256 constant NFT_ITEM_POOL = 31; //ItemDrops/build/NftItemPool.abi features=item-pool
    uint256 constant SWAP_RELAY_V1 = 32; //Prime/master/build/SwapRelayV1.abi
    uint256 constant SMART_RELAY = 33; //SmartLicense/build/SmartRelay.abi features=smart-relay
    uint256 constant SWAP_NFT_RELAY = 34; //Nft/build/SwapNftRelay.abi features=nft-swap
    uint256 constant GAME_NFT = 35; //Nft/build/GameNft.abi features=erc721

    uint256 constant PRIME_DEPLOYER = 50;  //Prime/master/build/PrimeDeployer.abi features=deployer
    uint256 constant DAICO_DEPLOYER = 51;  //Daico/build/DaicoDeployer.abi features=deployer
    uint256 constant PRIME_GIVER = 52;  //Prime/master/build/PrimeGiver.abi
    uint256 constant FORUM_DEPLOYER = 53;  //Forum/build/ForumDeployer.abi features=deployer
    uint256 constant COMMUNITY_DEPLOYER = 54;  //Community/build/CommunityDeployer.abi features=deployer
    uint256 constant ITEM_DROPS_DEPLOYER = 55;  //ItemDrops/build/ItemDropsDeployer.abi features=deployer
    uint256 constant BOOK_DEPLOYER = 56;  //Book/build/BookDeployer.abi features=deployer
    uint256 constant SMART_LICENSE_DEPLOYER = 57;  //SmartLicense/build/SmartLicenseDeployer.abi features=deployer
    uint256 constant HOURGLASS_DEPLOYER = 58;  //Hourglass/build/HourglassDeployer.abi features=deployer
    uint256 constant NFT_DEPLOYER = 59;  //Nft/build/NftDeployer.abi features=deployer

    uint256 constant PROXY_TOKEN = 100;  //Proxy/build/ProxyToken.abi features=erc20
    uint256 constant PROXY_TOKEN_DEPLOYER = 101;  //Proxy/build/ProxyTokenDeployer.abi features=deployer
    uint256 constant PROXY_DEPLOYER = 102;  //Proxy/build/ProxyDeployer.abi features=deployer
    uint256 constant PROXY_SWAPPER = 103;  //Proxy/build/ProxySwapper.abi
    uint256 constant CROSSCHAIN_TOKEN = 104;  //Crosschain/build/CrosschainToken.abi features=erc20
    uint256 constant CROSSCHAIN_DEPLOYER = 105;  //Crosschain/build/CrosschainDeployer.abi features=deployer
    uint256 constant REFUNDS_DEPLOYER = 106;  //Refund/build/RefundsDeployer.abi features=deployer
    uint256 constant SWAPPER_DEPLOYER = 107;  //Swapper/build/SwapperDeployer.abi features=deployer

    uint256 constant RESERVED1 = 1001;

    uint256 public bwtype;
    uint256 public bwver;
}

// SPDX-License-Identifier: LicenseRef-Blockwell-Smart-License
pragma solidity >=0.4.25;

/**
 * Gas-efficient error codes and replacement for require.
 *
 * This uses significantly less gas, and reduces the length of the contract bytecode.
 */
contract ErrorCodes {

    bytes2 constant ERROR_RESERVED = 0xe100;
    bytes2 constant ERROR_RESERVED2 = 0xe200;
    bytes2 constant ERROR_MATH = 0xe101;
    bytes2 constant ERROR_FROZEN = 0xe102;
    bytes2 constant ERROR_INVALID_ADDRESS = 0xe103;
    bytes2 constant ERROR_ZERO_VALUE = 0xe104;
    bytes2 constant ERROR_INSUFFICIENT_BALANCE = 0xe105;
    bytes2 constant ERROR_WRONG_TIME = 0xe106;
    bytes2 constant ERROR_EMPTY_ARRAY = 0xe107;
    bytes2 constant ERROR_LENGTH_MISMATCH = 0xe108;
    bytes2 constant ERROR_UNAUTHORIZED = 0xe109;
    bytes2 constant ERROR_DISALLOWED_STATE = 0xe10a;
    bytes2 constant ERROR_TOO_HIGH = 0xe10b;
    bytes2 constant ERROR_ERC721_CHECK = 0xe10c;
    bytes2 constant ERROR_PAUSED = 0xe10d;
    bytes2 constant ERROR_NOT_PAUSED = 0xe10e;
    bytes2 constant ERROR_ALREADY_EXISTS = 0xe10f;

    bytes2 constant ERROR_OWNER_MISMATCH = 0xe110;
    bytes2 constant ERROR_LOCKED = 0xe111;
    bytes2 constant ERROR_TOKEN_LOCKED = 0xe112;
    bytes2 constant ERROR_ATTORNEY_PAUSE = 0xe113;
    bytes2 constant ERROR_VALUE_MISMATCH = 0xe114;
    bytes2 constant ERROR_TRANSFER_FAIL = 0xe115;
    bytes2 constant ERROR_INDEX_RANGE = 0xe116;
    bytes2 constant ERROR_PAYMENT = 0xe117;
    bytes2 constant ERROR_BAD_PARAMETER_1 = 0xe118;
    bytes2 constant ERROR_BAD_PARAMETER_2 = 0xe119;

    function expect(bool pass, bytes2 code) internal pure {
        if (!pass) {
            assembly {
                mstore(0x40, code)
                revert(0x40, 0x02)
            }
        }
    }
}

// SPDX-License-Identifier: LicenseRef-Blockwell-Smart-License
pragma solidity >=0.8.9;

error Unauthorized(uint8 group);

/**
 * @dev Unified system for arbitrary user groups.
 *
 * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
 */
library Groups {
    struct MemberMap {
        mapping(address => bool) members;
    }

    struct GroupMap {
        mapping(uint8 => MemberMap) groups;
    }

    /**
     * @dev Add an account to a group
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function add(
        GroupMap storage map,
        uint8 groupId,
        address account
    ) internal {
        MemberMap storage group = map.groups[groupId];
        require(account != address(0));
        require(!groupContains(group, account));

        group.members[account] = true;
    }

    /**
     * @dev Remove an account from a group
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function remove(
        GroupMap storage map,
        uint8 groupId,
        address account
    ) internal {
        MemberMap storage group = map.groups[groupId];
        require(account != address(0));
        require(groupContains(group, account));

        group.members[account] = false;
    }

    /**
     * @dev Returns true if the account is in the group
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     * @return bool
     */
    function contains(
        GroupMap storage map,
        uint8 groupId,
        address account
    ) internal view returns (bool) {
        MemberMap storage group = map.groups[groupId];
        return groupContains(group, account);
    }

    function groupContains(MemberMap storage group, address account) internal view returns (bool) {
        require(account != address(0));
        return group.members[account];
    }
}
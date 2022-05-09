/**
 *Submitted for verification at Etherscan.io on 2022-05-08
*/

/**
 *Submitted for verification at Etherscan.io on 2022-05-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

interface ILegendsOfAtlantis {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

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

contract Staking is IERC721Receiver, ReentrancyGuard {

    address public owner;

    struct Stake {
        uint256 tokenId;
        address owner;
        uint256 startTime;
    }

    event stakeAdded(uint256 _id);
    event stakeRemoved(uint256 _id);

    mapping(uint256 => Stake) public stakes;
    mapping(address => uint256[]) public stakesByOwner;

    ILegendsOfAtlantis legendsOfAtlantis;

    constructor() {
        legendsOfAtlantis = ILegendsOfAtlantis(0x7746B7eF168547B61890E6B7Ce2CC6a1FE40C872);
        owner = msg.sender;
    }

    function stake(uint256 _id) public nonReentrant {
        address caller = msg.sender;
        require(msg.sender == tx.origin, "Only EOA!");
        // check if caller is owner of nft
        require(legendsOfAtlantis.ownerOf(_id) == caller, "Not an owner of NFT!");
        // update stakes & stakes by owner
        stakes[_id] = Stake({
            tokenId: _id,
            owner: caller,
            startTime: block.timestamp
        });
        // stakesByOwner[caller].push(_id);
        for (uint256 j=0; j<stakesByOwner[caller].length + 1; j++) {
            if (stakesByOwner[caller].length == j) {
                stakesByOwner[caller].push(_id);
                break;
            } else if (stakesByOwner[caller][j] == 0) {
                stakesByOwner[caller][j] = _id;
                break;
            }
        }
        // transfer nft to smart contract
        legendsOfAtlantis.safeTransferFrom(caller, address(this), _id);

        emit stakeAdded(_id);
    }

    function stakeMany(uint256[] memory _wallet) public nonReentrant {
        address caller = msg.sender;
        require(msg.sender == tx.origin, "Only EOA!");
        // iterate over caller IDs
        for (uint256 i=0; i<_wallet.length; i++) {
            uint256 _id = _wallet[i];
            // check if caller is owner of nft
            require(legendsOfAtlantis.ownerOf(_id) == caller, "Not an owner of NFT!");
            // update stakes & stakes by owner
            stakes[_id] = Stake({
                tokenId: _id,
                owner: caller,
                startTime: block.timestamp
            });
            // stakesByOwner[caller].push(_id);
            for (uint256 j=0; j<stakesByOwner[caller].length + 1; j++) {
                if (stakesByOwner[caller].length == j) {
                    stakesByOwner[caller].push(_id);
                    break;
                } else if (stakesByOwner[caller][j] == 0) {
                    stakesByOwner[caller][j] = _id;
                    break;
                }
            }
            // transfer nft to smart contract
            legendsOfAtlantis.safeTransferFrom(caller, address(this), _id);

            emit stakeAdded(_id);
        }
    }

    function unstake(uint256 _id) public nonReentrant {
        address caller = msg.sender;
        require(msg.sender == tx.origin, "Only EOA!");
        // check if caller is owner of nft & time staked longer than 2 days
        require(stakes[_id].owner == msg.sender, "Not an owner of NFT!");
        require(getStakeTime(_id) > 172_800, "You can unstake only after 2 days");
        // update stakes & stakes by owner
        delete stakes[_id];
        for (uint256 j=0; j<stakesByOwner[caller].length; j++) {
            if (stakesByOwner[caller][j] == _id) {
                delete stakesByOwner[caller][j];
            }
        }
        // transfer nft to caller
        legendsOfAtlantis.safeTransferFrom(address(this), caller, _id);

        emit stakeRemoved(_id);
    }

    function unstakeMany(uint256[] memory _wallet) public nonReentrant {
        address caller = msg.sender;
        require(msg.sender == tx.origin, "Only EOA!");
        // iterate over caller IDs
        for (uint256 i=0; i<_wallet.length; i++) {
            uint256 _id = _wallet[i];
            // check if caller is owner of nft & time staked longer than 2 days
            require(stakes[_id].owner == caller, "Not an owner of NFT!");
            require(getStakeTime(_id) > 172_800, "You can unstake only after 2 days!");
            // update stakes & stakes by owner
            delete stakes[_id];
            for (uint256 j=0; j<stakesByOwner[caller].length; j++) {
                if (stakesByOwner[caller][j] == _id) {
                    delete stakesByOwner[caller][j];
                }
            }
            // transfer nft to caller
            legendsOfAtlantis.safeTransferFrom(address(this), caller, _id);

            emit stakeRemoved(_id);
        }
    }

    function emergencyUnstake(uint256 _id) public {
        require(msg.sender == owner, "You are not an owner!");
        address stakeOwner = stakes[_id].owner;
        delete stakes[_id];
        for (uint256 j=0; j<stakesByOwner[stakeOwner].length; j++) {
                if (stakesByOwner[stakeOwner][j] == _id) {
                    delete stakesByOwner[stakeOwner][j];
                }
            }
        legendsOfAtlantis.safeTransferFrom(address(this), owner, _id);
    }

    function getStakeTime(uint256 _id) public view returns(uint256) {
        return (block.timestamp - stakes[_id].startTime);
    }

    function getStakeOwner(uint256 _id) public view returns(address) {
        return stakes[_id].owner;
    }

    function getStakesByOwner(address _owner) public view returns(uint256[] memory) {
        return stakesByOwner[_owner];
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) pure external override returns(bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
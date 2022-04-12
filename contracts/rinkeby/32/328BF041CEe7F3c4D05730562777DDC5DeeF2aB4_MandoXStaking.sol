// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.4;

import "./Context.sol";
import "./Ownable.sol";
import "./MandoX.sol";
import "./Lacedameon.sol";
import "./Pausable.sol";

contract MandoXStaking is Ownable, IERC721Receiver, Pausable {
    // struct to store a sta ke's token, owner, and lastCalimed
    struct Stake {
        uint16 tokenId;
        uint80 lastCalimed;
        address owner;
    }

    event TokenStaked(address owner, uint256 tokenId, uint256 lastCalimed);
    event MandoxClaimed(uint256 tokenId, uint256 earned, bool unstaked);

    // reference to the Lacedameon NFT contract
    Lacedameon lacedameon;
    // reference to the $Mandox contract for $MNX earnings
    MandoX mandox;

    // maps tokenId to stake
    mapping(uint256 => Stake) public registery;

    mapping(address => uint256[]) public stakedTokens;

    address public rewardingWallet;

    // Nft earn 1 $Mandox per day
    uint256 public constant DAILY_MANDOX_RATE = 1 ether;
    // Nft must have 2 days worth of $Mandox to unstake or else it's too cold
    uint256 public constant MINIMUM_TO_EXIT = 2 days;

    // amount of $Mandox earned so far
    uint256 public totalMandoxEarned;
    // number of Nft staked in the Registery
    uint256 public totalMandoxStaked;
    // the last time $Mandox was claimed
    uint256 public lastClaimTimestamp;

    // emergency rescue to allow unstaking without any checks but without $MANDOX
    bool public rescueEnabled = false;

    constructor(address _lacedameon, address payable _mandox, address _rewardingWallet) { 
        lacedameon = Lacedameon(_lacedameon);
        mandox = MandoX(_mandox);
        rewardingWallet = _rewardingWallet;
    }

    function addManyToRegistery(address account, uint16[] calldata tokenIds) external {
        require(account == _msgSender() || _msgSender() == address(lacedameon), "MANDOX: CAN NOT STAKE");
        for (uint i = 0; i < tokenIds.length; i++) {
            if (_msgSender() != address(lacedameon)) { // dont do this step if its a mint + stake
                require(lacedameon.ownerOf(tokenIds[i]) == _msgSender(), "MANDOX: IS NOT OWNER");
                lacedameon.transferFrom(_msgSender(), address(this), tokenIds[i]);
            } else if (tokenIds[i] == 0) {
                continue; // there may be gaps in the array for stolen tokens
            }
            _addNftToRegistery(account, tokenIds[i]);
        }
    }

    function _addNftToRegistery(address account, uint256 tokenId) internal whenNotPaused _updateEarnings {
        registery[tokenId] = Stake({
            owner: account,
            tokenId: uint16(tokenId),
            lastCalimed: uint80(block.timestamp)
        });
        stakedTokens[account].push(tokenId);
        totalMandoxStaked += 1;
        emit TokenStaked(account, tokenId, block.timestamp);
    }

    /** CLAIMING / UNSTAKING */

    /**
    * realize $MANDOX earnings and optionally unstake tokens from the Registery
    * to unstake a Nft it will require it has 2 days worth of $MANDOX unclaimed
    * @param tokenIds the IDs of the tokens to claim earnings from
    * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
    */
    function claimManyFromRegistery(uint16[] calldata tokenIds, bool unstake) external whenNotPaused _updateEarnings {
        uint256 rewards = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            rewards += _claimNftFromRegistery(tokenIds[i], unstake);
        }
        if (rewards == 0) return;
        mandox.transferFrom(rewardingWallet, _msgSender(), rewards);
    }

    /**
    * realize $MANDOX earnings for a single NFT and optionally unstake it
    * if not unstaking, pay a 20% tax to the staked Wolves
    * if unstaking, there is a 50% chance all $MANDOX is stolen
    * @param tokenId the ID of the NFT to claim earnings from
    * @param unstake whether or not to unstake the NFT
    * @return rewards - the amount of $MANDOX earned
    */
    function _claimNftFromRegistery(uint256 tokenId, bool unstake) internal returns (uint256 rewards) {
        Stake memory stake = registery[tokenId];
        require(stake.owner == _msgSender(), "MANDOX: SHOULD BE OWNER");
        require(!(unstake && block.timestamp - stake.lastCalimed < MINIMUM_TO_EXIT), "MANDOX: CAN NOT CLAIM YET");
        if (totalMandoxEarned < mandox.balanceOf(rewardingWallet)) {
            rewards = (block.timestamp - stake.lastCalimed) * DAILY_MANDOX_RATE / 1 days;
        } else if (stake.lastCalimed > lastClaimTimestamp) {
            rewards = 0; // $MANDOX production stopped already
        } else {
            rewards = (lastClaimTimestamp - stake.lastCalimed) * DAILY_MANDOX_RATE / 1 days; // stop earning additional $MANDOX if it's all been earned
        }
        if (unstake) {
            lacedameon.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back NFT
            delete registery[tokenId];
            for (uint i = 0; i < stakedTokens[_msgSender()].length; i++) {
                if (stakedTokens[_msgSender()][i] == tokenId) {
                    delete stakedTokens[_msgSender()][i];
                }
            }
            totalMandoxStaked -= 1;
        } else {
            registery[tokenId] = Stake({
                owner: _msgSender(),
                tokenId: uint16(tokenId),
                lastCalimed: uint80(block.timestamp)
            }); // reset stake
        }
        emit MandoxClaimed(tokenId, rewards, unstake);
    }


    /**
    * emergency unstake tokens
    * @param tokenIds the IDs of the tokens to claim earnings from
    */
    function rescue(uint256[] calldata tokenIds) external {
        require(rescueEnabled, "MANDOX: RESCUE DISABLED");
        uint256 tokenId;
        Stake memory stake;
        for (uint i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            stake = registery[tokenId];
            require(stake.owner == _msgSender(), "MANDOX: SHOULD BE OWNER");
            lacedameon.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Lacedameon
            delete registery[tokenId];
            totalMandoxStaked -= 1;
            emit MandoxClaimed(tokenId, 0, true);
        }
    }

    modifier _updateEarnings() {
        if (totalMandoxEarned < mandox.balanceOf(rewardingWallet)) {
            totalMandoxEarned += 
                (block.timestamp - lastClaimTimestamp)
                * totalMandoxStaked
                * DAILY_MANDOX_RATE / 1 days; 
            lastClaimTimestamp = block.timestamp;
        }
        _;
    }


    /**
    * allows owner to enable "rescue mode"
    * simplifies accounting, prioritizes tokens out in emergency
    */
    function setRescueEnabled(bool _enabled) external onlyOwner {
        rescueEnabled = _enabled;
    }
    /**
    * enables owner to pause / unpause claiming
    */
    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "MANDOX: CAN NOT STAKE DIRECTLY");
        return IERC721Receiver.onERC721Received.selector;
    }
}
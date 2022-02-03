// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IAtopia.sol";
import "./interfaces/IPortal.sol";

contract Castle {

    address implementation_;
    address public admin;
    
    address public portal;
    address public atopia;
    address public abucks;

    mapping (address => address) public reflection;
    mapping (uint256 => address) public apeOwner;

    function initialize(address portal_, address atopia_, address abucks_) external {
        require(msg.sender == admin);
        portal = portal_;
        atopia   = atopia_;
        abucks = abucks_;
    }

    function setReflection(address key_, address reflection_) external {
        require(msg.sender == admin);
        reflection[key_] = reflection_;
        reflection[reflection_] = key_;
    }

    /// @dev Send tokens to PolyLand
    function travel(uint256[] calldata ids, uint256 abucksAmount) external {
        address target = reflection[address(this)];

        uint256 apesLen   = ids.length;
        uint256 currIndex = 0;

        bytes[] memory calls = new bytes[]((apesLen > 0 ? apesLen + 1 : 0) + (abucksAmount > 0 ? 1 : 0));

        if (apesLen > 0) {
            _pullIds(atopia, ids);

            // This will create apes exactly as they exist in this chain
            for (uint256 i = 0; i < ids.length; i++) {
                calls[i] = _buildData(ids[i]);
            }

            calls[apesLen] = abi.encodeWithSelector(this.unstakeMany.selector,reflection[atopia], msg.sender,  ids);
            currIndex += apesLen + 1;
        }

        if (abucksAmount > 0) {
            IBucks(abucks).burnFrom(msg.sender, abucksAmount);
            calls[currIndex] = abi.encodeWithSelector(this.callAtopia.selector, abi.encodeWithSelector(IAtopia.mintAbucks.selector, msg.sender, abucksAmount));
            currIndex++;
        }

        PortalLike(portal).sendMessage(abi.encode(target, calls));
    }

    function callAtopia(bytes calldata data) external {
        _onlyPortal();

        (bool succ, ) = atopia.call(data);
        require(succ);
    }

    event D(uint tt);
    event DAD(address al);

    function unstakeMany(address token, address owner, uint256[] calldata ids) external {
        _onlyPortal();

        emit DAD(token);

        for (uint256 i = 0; i < ids.length; i++) {  
            emit D(ids[i]);
            if (token == atopia)   delete apeOwner[ids[i]];
            ERC721Like(token).transfer(owner, ids[i]);
        }
    }

    function _pullIds(address token, uint256[] calldata ids) internal {
        // The ownership will be checked to the token contract
        IAtopia(token).pull(msg.sender, ids);
    }

    function pullCallback(address owner, uint256[] calldata ids) external {
        require(msg.sender == atopia);
        for (uint256 i = 0; i < ids.length; i++) {
            _stake(msg.sender, ids[i], owner);
        }
    }

    function _buildData(uint256 id) internal view returns (bytes memory data) {
        IAtopia.ApeData memory ape = IAtopia(atopia).getTokenAttribs(id);
        data = abi.encodeWithSelector(this.callAtopia.selector, abi.encodeWithSelector(IAtopia.adjustApe.selector, id, ape.name, ape.trait, ape.info));
    }

    function _stake(address token, uint256 id, address owner) internal {
        require(apeOwner[id] == address(0), "already staked");
        require(msg.sender == token, "not atopia contract");
        require(ERC721Like(token).ownerOf(id) == address(this), "ape not transferred");

        if (token == atopia)   apeOwner[id]  = owner;
    }

    function _onlyPortal() view internal {
        require(msg.sender == portal, "not portal");
    } 
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IBucks.sol";

interface IAtopia {
	function owner() external view returns (address);

	function bucks() external view returns (IBucks);

	function getAge(uint256 tokenId) external view returns (uint256);

	struct ApeData {
		string name;
		uint256 trait;
		uint256 info;
	}
	function getTokenAttribs(uint256 tokenId) external view returns (ApeData memory);

	function ownerOf(uint256 tokenId) external view returns (address);

	function update(uint256 tokenId) external;

	function exitCenter(
		uint256 tokenId,
		uint256 grown,
		uint256 enjoyFee
	) external returns (uint256);

	function addReward(uint256 tokenId, uint256 reward) external;

	function claimGrowth(
		uint256 tokenId,
		uint256 grown,
		uint256 enjoyFee
	) external returns (uint256);

	function claimBucks(address user, uint256 amount) external;

	function buyAndUseItem(
		uint256 tokenId,
		uint256 itemInfo
	) external;

	function pull(address owner_, uint256[] calldata ids) external;

	function adjustApe(uint256 id, string memory name, uint256 trait_, uint256 info) external;

	function mintAbucks(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBucks {
	function mint(address account, uint256 amount) external;

	function burn(uint256 amount) external;

	function burnFrom(address account, uint256 amount) external;

	function transfer(address recipient, uint256 amount) external returns (bool);

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) external returns (bool);

	function balanceOf(address account) external view returns (uint256);
}

interface PortalLike {
    function sendMessage(bytes calldata message_) external;
}

interface CastleLike {
    function pullCallback(address owner, uint256[] calldata ids) external;
}

interface ERC20Like {
    function balanceOf(address from) external view returns(uint256 balance);
    function burn(address from, uint256 amount) external;
    function mint(address from, uint256 amount) external;
    function transfer(address to, uint256 amount) external;
}

interface ERC1155Like {
    function mint(address to, uint256 id, uint256 amount) external;
    function burn(address from, uint256 id, uint256 amount) external;
}

interface ERC721Like {
    function transferFrom(address from, address to, uint256 id) external;   
    function transfer(address to, uint256 id) external;
    function ownerOf(uint256 id) external returns (address owner);
    function mint(address to, uint256 tokenid) external;
}
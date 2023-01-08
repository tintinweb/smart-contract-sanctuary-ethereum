// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./libraries/LibDiamond.sol";
import "./libraries/LibSignetStorage.sol";
import "./libraries/LibVerify.sol";
import "./interfaces/ISignetor.sol";
/*
 * @title Signet Controllor Facet
 * @author https://outerspace.ai/
 */

error Already__Registered();
error Wrong__User();
error Un__Registered();
error Not_Owner();
error Not__EnoughAmount();

contract ControllorFacet {
    AppStorage s;
    modifier onlyOwner() {
        address _owner = owner();
        if (_owner != msg.sender) revert Not_Owner();
        _;
    }

    modifier noReentrant() {
        require(!s.locked, "Reentrancy Protection");
        s.locked = true;
        _;
        s.locked = false;
    }

    modifier Registered() {
        if (LibSignetStorage.checkRegistered(msg.sender) == false) revert Un__Registered();
        _;
    }

    event UserRegistered(
        address indexed userAddress,
        bytes userSig,
        uint256 indexed timeRegistered
    );

    event NewMessageSent(
        address indexed messageSender,
        uint256 messageId,
        uint256 signetId,
        string tokenURI_,
        uint256 time
    );

    event MessageDeleted(address indexed messageSender, uint256 signetId, uint256 time);

    /*
     * @notice Method creating signetorContract.
     * @param store all infos into contract.
     */

    function register(
        string calldata _name,
        string calldata _version,
        address from,
        string calldata _notice,
        bytes calldata _signature
    ) external {
        if (LibSignetStorage.checkRegistered(msg.sender) == true) revert Already__Registered();
        address user = LibVerify.verify(_name, _version, from, address(this), _notice, _signature);
        if (user != msg.sender) revert Wrong__User();
        LibSignetStorage.register(msg.sender);
        emit UserRegistered(msg.sender, _signature, block.timestamp);
    }

    function sendMessage(
        string memory tokenURI_
    ) public payable Registered returns (bool success) {
        if (msg.value < LibSignetStorage.getValueForSendMessage()) revert Not__EnoughAmount();
        uint256 tokenId = ISignetor(LibSignetStorage.getSignetorAddress()).sendMessage(
            msg.sender,
            tokenURI_
        );
        uint256 messageId = LibSignetStorage.messageSent(msg.sender);
        emit NewMessageSent(msg.sender, tokenId, messageId, tokenURI_, block.timestamp);
        return true;
    }

    function deleteMessage(uint256 tokenId) public payable Registered returns (bool success) {
        ISignetor(LibSignetStorage.getSignetorAddress()).deleteMessage(msg.sender, tokenId);
        LibSignetStorage.messageDelete(msg.sender);
        emit MessageDeleted(msg.sender, tokenId, block.timestamp);
        return true;
    }

    function owner() internal view returns (address owner_) {
        owner_ = LibDiamond.contractOwner();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


import "./ECDSA.sol";

library LibVerify {

    function _domainSeparatorV4(
        bytes32 hashedName,
        bytes32 hashedVersion,
        bytes32 typeHash
    ) internal view returns (bytes32) {
        return _buildDomainSeparator(typeHash, hashedName, hashedVersion);
    }

    function _hash(
        bytes32 hashedName,
        bytes32 hashedVersion,
        bytes32 typeHash,
        address from,
        address to,
        string calldata notice
    ) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256("signetAction(address from,address to,string notice)"),
                        from,
                        to,
                        keccak256(bytes(notice))
                    )
                ),
                hashedName,
                hashedVersion,
                typeHash
            );
    }

    function verify(
        string calldata name,
        string calldata version,
        address from,
        address to,
        string calldata notice,
        bytes calldata signature
    ) internal view returns (address) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        bytes32 hash = _hash(hashedName, hashedVersion, typeHash, from, to, notice);
        return ECDSA.recover(hash, signature);
    }

    function _hashTypedDataV4(
        bytes32 structHash,
        bytes32 hashedName,
        bytes32 hashedVersion,
        bytes32 typeHash
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    _domainSeparatorV4(hashedName, hashedVersion, typeHash),
                    structHash
                )
            );
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 name,
        bytes32 version
    ) internal view returns (bytes32) {
        return keccak256(abi.encode(typeHash, name, version, block.chainid, address(this)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ISignetor {
    function sendMessage(
        address messageSender,
        string memory tokenURI_
    ) external returns (uint256);

    function deleteMessage(address messageOwner, uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IDiamondCut} from "../interfaces/IDiamondCut.sol";

library LibDiamond {
    error InValidFacetCutAction();
    error NotDiamondOwner();
    error NoSelectorsInFacet();
    error NoZeroAddress();
    error SelectorExists(bytes4 selector);
    error SameSelectorReplacement(bytes4 selector);
    error MustBeZeroAddress();
    error NoCode();
    error NonExistentSelector(bytes4 selector);
    error ImmutableFunction(bytes4 selector);
    error NonEmptyCalldata();
    error EmptyCalldata();
    error InitCallFailed();
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        if (msg.sender != diamondStorage().contractOwner) revert NotDiamondOwner();
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else {
                revert InValidFacetCutAction();
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        if (_functionSelectors.length <= 0) revert NoSelectorsInFacet();
        DiamondStorage storage ds = diamondStorage();
        if (_facetAddress == address(0)) revert NoZeroAddress();
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            if (oldFacetAddress != address(0)) revert SelectorExists(selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        if (_functionSelectors.length <= 0) revert NoSelectorsInFacet();
        DiamondStorage storage ds = diamondStorage();
        if (_facetAddress == address(0)) revert NoZeroAddress();
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            if (oldFacetAddress == _facetAddress) revert SameSelectorReplacement(selector);
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        if (_functionSelectors.length <= 0) revert NoSelectorsInFacet();
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        if (_facetAddress != address(0)) revert MustBeZeroAddress();
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress);
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }

    function addFunction(
        DiamondStorage storage ds,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(
        DiamondStorage storage ds,
        address _facetAddress,
        bytes4 _selector
    ) internal {
        if (_facetAddress == address(0)) revert NonExistentSelector(_selector);
        // an immutable function is a function defined directly in a diamond
        if (_facetAddress == address(this)) revert ImmutableFunction(_selector);
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition;
        uint256 lastSelectorPosition = ds
            .facetFunctionSelectors[_facetAddress]
            .functionSelectors
            .length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[
                lastSelectorPosition
            ];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[
                selectorPosition
            ] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(
                selectorPosition
            );
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds
                    .facetFunctionSelectors[lastFacetAddress]
                    .facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            if (_calldata.length > 0) revert NonEmptyCalldata();
        } else {
            if (_calldata.length == 0) revert EmptyCalldata();
            if (_init != address(this)) {
                enforceHasContractCode(_init);
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert InitCallFailed();
                }
            }
        }
    }

    function enforceHasContractCode(address _contract) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        if (contractSize <= 0) revert NoCode();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../storage/AppStorage.sol";
import "./SafeMath.sol";
import "../interfaces/IERC721.sol";
import "../interfaces/IERC1155.sol";

/*
 * @title Signet LibSignetStorage
 * @author https://outerspace.ai/
 */
library LibSignetStorage {
    bytes32 internal constant RENTAL = keccak256("signet.lib.storage");

    function getStorage() internal pure returns (AppStorage storage s) {
        bytes32 position = RENTAL;
        assembly {
            s.slot := position
        }
    }

    function register(address _user) internal {
        AppStorage storage s = getStorage();
        s.ma.register[_user] = true;
        unchecked {
            ++s.cs.totalSignetorsNum;
        }
    }

    function setSignetorAddress(address _signetorAddress) internal {
        AppStorage storage s = getStorage();
        s.signetorAddress = _signetorAddress;
    }

    function getSignetorAddress() internal view returns (address) {
        AppStorage storage s = getStorage();
        return (s.signetorAddress);
    }

    function getAllowedTranfer() internal view returns (bool) {
        AppStorage storage s = getStorage();
        return (s.cs.allowTranfer);
    }

    function setAllowedTranfer(bool _allowedTranfer) internal {
        AppStorage storage s = getStorage();
        s.cs.allowTranfer = _allowedTranfer;
    }

    function getValueForSendMessage() internal view returns (uint256) {
        AppStorage storage s = getStorage();
        return (s.cs.messagePrice);
    }

    function setValueForSendMessage(uint256 _messagePrice) internal {
        AppStorage storage s = getStorage();
        s.cs.messagePrice = _messagePrice;
    }

    function getTotalSignetorNum() internal view returns (uint256) {
        AppStorage storage s = getStorage();
        return (s.cs.totalSignetorsNum);
    }

    function hasName(address _signetUserAddress) internal view returns (bool) {
        AppStorage storage s = getStorage();
        uint256 i = 0;
        do {
            if (s.pm.name[i].owner == _signetUserAddress) {
                return true;
            }
            unchecked {
                ++i;
            }
        } while (i < s.ps.totalName + 1);
        return false;
    }

    function checkName(address _signetUserAddress) internal view returns (string memory) {
        AppStorage storage s = getStorage();
        uint256 i = 0;
        do {
            if (s.pm.name[i].owner == _signetUserAddress) {
                return (s.pm.name[i].name);
            }
            unchecked {
                ++i;
            }
        } while (i < s.ps.totalName + 1);
        return "You seeing this message is becuase this address don't have any name created!";
    }

    function checkNameAddress(string memory _name) internal view returns (bool, address) {
        AppStorage storage s = getStorage();
        uint256 i = 0;
        do {
            if (
                keccak256(abi.encodePacked(s.pm.name[i].name)) ==
                keccak256(abi.encodePacked(_name))
            ) {
                return (true, s.pm.name[i].owner);
            }
            unchecked {
                ++i;
            }
        } while (i < s.ps.totalName + 1);
        return (false, address(0));
    }

    function checkNameAvalable(string memory _name) internal view returns (bool) {
        AppStorage storage s = getStorage();
        uint256 i = 0;
        do {
            if (
                keccak256(abi.encodePacked(s.pm.name[i].name)) ==
                keccak256(abi.encodePacked(_name))
            ) {
                return false;
            }
            unchecked {
                ++i;
            }
        } while (i < s.ps.totalName + 1);
        return true;
    }

    function findNameId(string memory _name) internal view returns (uint256 id) {
        AppStorage storage s = getStorage();
        uint256 i = 0;
        do {
            if (
                keccak256(abi.encodePacked(s.pm.name[i].name)) ==
                keccak256(abi.encodePacked(_name))
            ) {
                return (i);
            }
            unchecked {
                ++i;
            }
        } while (i < s.ps.totalName + 1);
        return (0);
    }

    function modifyNameForUser(string memory _newname, address _signetUserAddress) internal {
        AppStorage storage s = getStorage();
        if (hasName(_signetUserAddress) == false) {
            unchecked {
                ++s.ps.totalName;
            }
            s.pm.name[s.ps.totalName].name = _newname;
            s.pm.name[s.ps.totalName].timeUpdated = block.timestamp;
            s.pm.name[s.ps.totalName].owner = _signetUserAddress;
        }

        if (hasName(_signetUserAddress) == true) {
            string memory _oldname = checkName(_signetUserAddress);
            uint256 oldNameId = findNameId(_oldname);
            s.pm.name[oldNameId].name = _newname;
            s.pm.name[oldNameId].timeUpdated = block.timestamp;
        }
    }

    function hasPfp(address _signetUserAddress) internal view returns (bool) {
        AppStorage storage s = getStorage();
        uint256 i = 0;
        do {
            if (s.pm.pfp[i].owner == _signetUserAddress) {
                return true;
            }
            unchecked {
                ++i;
            }
        } while (i < s.ps.totalpfp + 1);
        return false;
    }

    function checkPfp(
        address _signetUserAddress
    ) internal view returns (string memory, address, uint256, uint256) {
        AppStorage storage s = getStorage();
        uint256 i = 0;
        do {
            if (s.pm.pfp[i].owner == _signetUserAddress) {
                return (
                    s.pm.pfp[i].pfp,
                    s.pm.pfp[i].collection,
                    s.pm.pfp[i].tokenId,
                    s.pm.pfp[i].typeOf
                );
            }
            unchecked {
                ++i;
            }
        } while (i < s.ps.totalpfp + 1);
        return (
            "You seeing this message is becuase this address don't have any pfp created!",
            address(0),
            0,
            0
        );
    }

    function findPfpId(string memory _pfp) internal view returns (uint256 id) {
        AppStorage storage s = getStorage();
        uint256 i = 0;
        do {
            if (
                keccak256(abi.encodePacked(s.pm.pfp[i].pfp)) == keccak256(abi.encodePacked(_pfp))
            ) {
                return (i);
            }
            unchecked {
                ++i;
            }
        } while (i < s.ps.totalpfp + 1);
        return (0);
    }

    function modifyPfpForUser(
        string memory _pfp,
        address _signetUserAddress,
        uint256 _tokenId,
        address _collection,
        uint256 _typeOf
    ) internal {
        AppStorage storage s = getStorage();
        if (hasPfp(_signetUserAddress) == false) {
            unchecked {
                ++s.ps.totalpfp;
            }
            s.pm.pfp[s.ps.totalpfp].pfp = _pfp;
            s.pm.pfp[s.ps.totalpfp].timeUpdated = block.timestamp;
            s.pm.pfp[s.ps.totalpfp].owner = _signetUserAddress;
            s.pm.pfp[s.ps.totalpfp].tokenId = _tokenId;
            s.pm.pfp[s.ps.totalpfp].collection = _collection;
            s.pm.pfp[s.ps.totalpfp].typeOf = _typeOf;
        }

        if (hasPfp(_signetUserAddress) == true) {
            (string memory _oldPfp, , , ) = checkPfp(_signetUserAddress);
            uint256 oldPfpId = findPfpId(_oldPfp);
            s.pm.pfp[oldPfpId].pfp = _pfp;
            s.pm.pfp[oldPfpId].timeUpdated = block.timestamp;
            s.pm.pfp[s.ps.totalpfp].tokenId = _tokenId;
            s.pm.pfp[s.ps.totalpfp].collection = _collection;
            s.pm.pfp[s.ps.totalpfp].typeOf = _typeOf;
        }
    }

    function messageSent(address signetor) internal returns (uint256) {
        AppStorage storage s = getStorage();
        unchecked {
            ++s.cs.totalSignetsNum;
        }
        unchecked {
            ++s.ma.numOfSignetsSent[signetor];
        }
        return (s.cs.totalSignetsNum);
    }

    function messageDelete(address signetor) internal {
        AppStorage storage s = getStorage();
        unchecked {
            --s.ma.numOfSignetsSent[signetor];
        }
    }

    function follow(address msgSender, address signetor) internal {
        AppStorage storage s = getStorage();
        unchecked {
            ++s.fm.follower[signetor].followerNum;
        }
        s.fm.follower[signetor].whoFollowed.push(msgSender);
        unchecked {
            ++s.fm.following[msgSender].FollowingNum;
        }
        s.fm.following[msgSender].followedWho.push(signetor);
    }

    function unfollow(address msgSender, address signetor) internal {
        AppStorage storage s = getStorage();

        uint256 totalFollower = s.fm.follower[signetor].followerNum;
        uint256 i = findfollowerId(signetor, msgSender);
        if (totalFollower == i) {
            unchecked {
                --s.fm.follower[signetor].followerNum;
            }
            s.fm.follower[signetor].whoFollowed.pop();
        } else {
            unchecked {
                --s.fm.follower[signetor].followerNum;
            }
            s.fm.follower[signetor].whoFollowed[i - 1] = s.fm.follower[signetor].whoFollowed[
                s.fm.follower[signetor].whoFollowed.length - 1
            ];
            s.fm.follower[signetor].whoFollowed.pop();
        }

        uint256 totalFollowing = s.fm.following[msgSender].FollowingNum;
        uint256 j = findFollwingId(msgSender, signetor);
        if (totalFollowing == j) {
            unchecked {
                --s.fm.following[msgSender].FollowingNum;
            }
            s.fm.following[msgSender].followedWho.pop();
        } else {
            unchecked {
                --s.fm.following[msgSender].FollowingNum;
            }
            s.fm.following[msgSender].followedWho[j - 1] = s.fm.following[msgSender].followedWho[
                s.fm.following[msgSender].followedWho.length - 1
            ];
            s.fm.following[msgSender].followedWho.pop();
        }
    }

    function like(address msgSender, uint256 SignetId) internal {
        AppStorage storage s = getStorage();
        unchecked {
            ++s.fm.signetState[SignetId].likeNum;
        }
        s.fm.signetState[SignetId].likeContributors.push(msgSender);
    }

    function unlike(address msgSender, uint256 SignetId) internal {
        AppStorage storage s = getStorage();

        uint256 totalFollower = s.fm.signetState[SignetId].likeNum;
        uint256 i = findLikeId(SignetId, msgSender);
        if (totalFollower == i) {
            unchecked {
                s.fm.signetState[SignetId].likeNum;
            }
            s.fm.signetState[SignetId].likeContributors.pop();
        } else {
            unchecked {
                s.fm.signetState[SignetId].likeNum;
            }
            s.fm.signetState[SignetId].likeContributors[i - 1] = s
                .fm
                .signetState[SignetId]
                .likeContributors[s.fm.signetState[SignetId].likeContributors.length - 1];
            s.fm.signetState[SignetId].likeContributors.pop();
        }
    }

    function star(address msgSender, address SignetIdOwner, uint256 SignetId) internal {
        AppStorage storage s = getStorage();
        unchecked {
            ++s.fm.Stars[SignetIdOwner];
        }
        unchecked {
            ++s.fm.signetState[SignetId].starNum;
        }
        s.fm.signetState[SignetId].starContributors.push(msgSender);
    }

    function setAppreciateAmount(uint256 _amount) internal {
        AppStorage storage s = getStorage();
        s.cs.appreciateAmount = _amount;
    }

    function getAppreciateAmount() internal view returns (uint256) {
        AppStorage storage s = getStorage();
        return (s.cs.appreciateAmount);
    }

    function setStarCommission(uint256 _starCommisionPercent) internal {
        AppStorage storage s = getStorage();
        s.cs.commission = _starCommisionPercent;
    }

    function getStarCommission() internal view returns (uint256) {
        AppStorage storage s = getStorage();
        return (s.cs.commission);
    }

    function checklikeable(
        address SignetIdOwner,
        uint256 SignetId
    ) internal view returns (bool result) {
        AppStorage storage s = getStorage();
        if (SignetId <= s.cs.totalSignetsNum) {
            if (s.cs.totalSignetsNum != 0) {
                if (SignetId != 0) {
                    if (IERC721(s.signetorAddress).ownerOf(SignetId) == SignetIdOwner) {
                        return (true);
                    }
                }
            }
        } else {
            return (false);
        }
    }

    function checkfollowed(
        address signetor,
        address followersaddress
    ) internal view returns (bool) {
        AppStorage storage s = getStorage();
        uint256 i = 0;
        do {
            if (s.fm.follower[signetor].whoFollowed[i] == followersaddress) {
                return (true);
            }
            unchecked {
                ++i;
            }
        } while (i < s.fm.follower[signetor].whoFollowed.length);
        return (false);
    }

    function checkliked(uint256 signetID, address likedAddress) internal view returns (bool) {
        AppStorage storage s = getStorage();
        uint256 i = 0;
        do {
            if (s.fm.signetState[signetID].likeContributors[i] == likedAddress) {
                return (true);
            }
            unchecked {
                ++i;
            }
        } while (i < s.fm.signetState[signetID].likeContributors.length);
        return (false);
    }

    function getTotalSignetsNum() internal view returns (uint256) {
        AppStorage storage s = getStorage();
        return (s.cs.totalSignetsNum);
    }

    function findfollowerId(
        address signetor,
        address followersaddress
    ) internal view returns (uint256 id) {
        AppStorage storage s = getStorage();
        uint256 i = 1;
        do {
            if (s.fm.follower[signetor].whoFollowed[i - 1] == followersaddress) {
                return i;
            }
            unchecked {
                ++i;
            }
        } while (i < s.fm.follower[signetor].whoFollowed.length + 1);
    }

    function findFollwingId(
        address signetor,
        address followingAaddress
    ) internal view returns (uint256 id) {
        AppStorage storage s = getStorage();
        uint256 i = 1;
        do {
            if (s.fm.following[signetor].followedWho[i - 1] == followingAaddress) {
                return i;
            }
            unchecked {
                ++i;
            }
        } while (i < s.fm.following[signetor].followedWho.length + 1);
    }

    function findLikeId(
        uint256 signetID,
        address likedAddress
    ) internal view returns (uint256 id) {
        AppStorage storage s = getStorage();
        uint256 i = 1;
        do {
            if (s.fm.signetState[signetID].likeContributors[i - 1] == likedAddress) {
                return i;
            }
            unchecked {
                ++i;
            }
        } while (i < s.fm.signetState[signetID].likeContributors.length + 1);
    }

    function getFollowingsNum(address signetor) internal view returns (uint256) {
        AppStorage storage s = getStorage();
        return (s.fm.following[signetor].FollowingNum);
    }

    function getFollowersNum(address signetor) internal view returns (uint256) {
        AppStorage storage s = getStorage();
        return (s.fm.follower[signetor].followerNum);
    }

    function getFollowers(address signetor) internal view returns (address[] memory) {
        AppStorage storage s = getStorage();
        return (s.fm.follower[signetor].whoFollowed);
    }

    function getFollowings(address signetor) internal view returns (address[] memory) {
        AppStorage storage s = getStorage();
        return (s.fm.following[signetor].followedWho);
    }

    function getStaredNumForSignetor(address signetor) internal view returns (uint256) {
        AppStorage storage s = getStorage();
        return (s.fm.Stars[signetor]);
    }

    function getLikedNum(uint256 signetId) internal view returns (uint256) {
        AppStorage storage s = getStorage();
        return (s.fm.signetState[signetId].likeNum);
    }

    function getStaredNum(uint256 signetId) internal view returns (uint256) {
        AppStorage storage s = getStorage();
        return (s.fm.signetState[signetId].starNum);
    }

    function getStarContributor(uint256 SignetId) internal view returns (address[] memory) {
        AppStorage storage s = getStorage();
        return (s.fm.signetState[SignetId].starContributors);
    }

    function getLikeContributor(uint256 SignetId) internal view returns (address[] memory) {
        AppStorage storage s = getStorage();
        return (s.fm.signetState[SignetId].likeContributors);
    }

    function checkRegistered(address _user) internal view returns (bool) {
        AppStorage storage s = getStorage();
        return (s.ma.register[_user]);
    }

    function checkNumOfSignetsSent(address _user) internal view returns (uint256) {
        AppStorage storage s = getStorage();
        return (s.ma.numOfSignetsSent[_user]);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.9;

import "./Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes memory signature
    ) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs &
            bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s)
            );
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(
        bytes32 domainSeparator,
        bytes32 structHash
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.9;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.9;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ProfileSysStorage.sol";
import "./FollowSysStorage.sol";
import "./ControllorStorage.sol";

struct AppStorage {
    profileStruct ps;
    nameStruct ns;
    pfpStruct pfps;
    profilemap pm;
    Followers flwr;
    Following flwi;
    signetinfo signetinfo;
    followMap fm;
    mapSignetAddress ma;
    controllorStorage cs;
    bool locked;
    address signetorAddress;
    address priceFeedAddress;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

struct profileStruct {
    uint256 totalName;
    uint256 totalpfp;
}
struct nameStruct {
    string name;
    uint256 timeUpdated;
    address owner;
}

struct pfpStruct {
    string pfp;
    uint256 timeUpdated;
    address owner;
    address collection;
    uint256 tokenId;
    uint256 typeOf;
}

struct profilemap {
    mapping(uint256 => pfpStruct) pfp;
    mapping(uint256 => nameStruct) name;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

struct controllorStorage {
    uint256 totalSignetorsNum;
    uint256 totalSignetsNum;
    uint256 appreciateAmount;
    uint256 commission;
    uint256 messagePrice;
    address signetprofileSys;
    address signetFollowSys;
    bool allowTranfer;
}
struct mapSignetAddress {
    mapping(address => bool) register;
    mapping(address => uint256) numOfSignetsSent;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

//followers struct
struct Followers {
    uint256 followerNum;
    address[] whoFollowed;
}

//following struct

struct Following {
    uint256 FollowingNum;
    address[] followedWho;
}

//star struct

struct signetinfo {
    uint256 likeNum;
    uint256 starNum;
    // address SignetIdOwner;
    address[] starContributors;
    address[] likeContributors;
}

struct followMap {
    mapping(address => Followers) follower;
    mapping(address => Following) following;
    mapping(uint256 => signetinfo) signetState;
    mapping(address => uint256) Stars;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
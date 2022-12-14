// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./libraries/LibDiamond.sol";
import "./libraries/LibSignetStorage.sol";

/*
 * @title Signetors SignetProfileSys
 * @author astro
 */
error Not_Owner();

contract TransferFacet {
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

    function getAllowedTranfer() public view returns (bool) {
        return (LibSignetStorage.getAllowedTranfer());
    }

    function setAllowedTranfer(bool _allowedTranfer) public onlyOwner {
        LibSignetStorage.setAllowedTranfer(_allowedTranfer);
    }

    function owner() internal view returns (address owner_) {
        owner_ = LibDiamond.contractOwner();
    }
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

library LibSignetStorage {
    bytes32 internal constant RENTAL = keccak256("signet.lib.storage");

    function getStorage() internal pure returns (AppStorage storage s) {
        bytes32 position = RENTAL;
        assembly {
            s.slot := position
        }
    }

    function getAllowedTranfer() internal view returns (bool) {
        AppStorage storage s = getStorage();
        return (s.cs.allowTranfer);
    }

    function setAllowedTranfer(bool _allowedTranfer) internal {
        AppStorage storage s = getStorage();
        s.cs.allowTranfer = _allowedTranfer;
    }

    function controllorCreateSignetor(address msgSender, address _b) internal {
        AppStorage storage s = getStorage();
        // if (getOwnerNumContractOfSignetor(msg.sender) != 0) revert Contract__Created();
        // (, address b, ) = STCrator.createSignetor(_name, _symbol, msg.sender);
        s.cs.TotalSignetorsNum++;
        s.ma.collectionContractList[_b] = msgSender;
    }

    function hasName(address _signetUserAddress) internal view returns (bool) {
        AppStorage storage s = getStorage();
        for (uint256 i = 0; i < s.ps.totalName + 1; i++) {
            if (s.pm.name[i].owner == _signetUserAddress) {
                return true;
            }
        }
        return false;
    }

    function checkName(address _signetUserAddress) internal view returns (string memory) {
        AppStorage storage s = getStorage();
        for (uint256 i = 0; i < s.ps.totalName + 1; i++) {
            if (s.pm.name[i].owner == _signetUserAddress) {
                return (s.pm.name[i].name);
            }
        }
        return "You seeing this message is becuase this address don't have any name created!";
    }

    function checkNameAvalable(string memory _name) internal view returns (bool) {
        AppStorage storage s = getStorage();
        for (uint256 i = 0; i < s.ps.totalName + 1; i++) {
            if (
                keccak256(abi.encodePacked(s.pm.name[i].name)) ==
                keccak256(abi.encodePacked(_name))
            ) {
                return false;
            }
        }
        return true;
    }

    function findNameId(string memory _name) internal view returns (uint256 id) {
        AppStorage storage s = getStorage();
        for (uint256 i = 0; i < s.ps.totalName + 1; i++) {
            if (
                keccak256(abi.encodePacked(s.pm.name[i].name)) ==
                keccak256(abi.encodePacked(_name))
            ) {
                return (i);
            }
        }
        return (0);
    }

    function modifyNameForUser(string memory _newname, address _signetUserAddress) internal {
        AppStorage storage s = getStorage();
        // specify below in the function contract
        // if (bytes(_newname).length > 12) revert name__IsTooLong();
        // if (checkNameAvalable(_newname) == false) revert name__IsNotAvalable();

        if (hasName(_signetUserAddress) == false) {
            s.ps.totalName++;
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
        for (uint256 i = 0; i < s.ps.totalpfp + 1; i++) {
            if (s.pm.pfp[i].owner == _signetUserAddress) {
                return true;
            }
        }
        return false;
    }

    function checkPfp(address _signetUserAddress) internal view returns (string memory) {
        AppStorage storage s = getStorage();
        for (uint256 i = 0; i < s.ps.totalpfp + 1; i++) {
            if (s.pm.pfp[i].owner == _signetUserAddress) {
                return (s.pm.pfp[i].pfp);
            }
        }
        return "You seeing this message is becuase this address don't have any pfp created!";
    }

    function findPfpId(string memory _pfp) internal view returns (uint256 id) {
        AppStorage storage s = getStorage();
        for (uint256 i = 0; i < s.ps.totalpfp + 1; i++) {
            if (
                keccak256(abi.encodePacked(s.pm.pfp[i].pfp)) == keccak256(abi.encodePacked(_pfp))
            ) {
                return (i);
            }
        }
        return (0);
    }

    function modifyPfpForUser(string memory _pfp, address _signetUserAddress) internal {
        AppStorage storage s = getStorage();
        if (hasPfp(_signetUserAddress) == false) {
            s.ps.totalpfp++;
            s.pm.pfp[s.ps.totalpfp].pfp = _pfp;
            s.pm.pfp[s.ps.totalpfp].timeUpdated = block.timestamp;
            s.pm.pfp[s.ps.totalpfp].owner = _signetUserAddress;
        }

        if (hasPfp(_signetUserAddress) == true) {
            string memory _oldPfp = checkPfp(_signetUserAddress);
            uint256 oldPfpId = findPfpId(_oldPfp);
            s.pm.pfp[oldPfpId].pfp = _pfp;
            s.pm.pfp[oldPfpId].timeUpdated = block.timestamp;
        }
    }

    function messageSender(address msgSender) internal returns (uint256) {
        AppStorage storage s = getStorage();
        s.fss.signetId++;
        s.fm.signetState[s.fss.signetId].SignetIdOwner = msgSender;
        return (s.fss.signetId);
    }

    function follow(address msgSender, address signetor) internal {
        AppStorage storage s = getStorage();
        // if (msgSender == signetor) revert Can__notfollow();
        bool result = checkfollowed(signetor, msgSender);
        if (result == false) {
            s.fm.follower[signetor].followerNum++;
            s.fm.follower[signetor].whoFollowed.push(msgSender);
            s.fm.following[msgSender].FollowingNum++;
            s.fm.following[msgSender].followedWho.push(signetor);
        }
    }

    function unfollow(address msgSender, address signetor) internal {
        AppStorage storage s = getStorage();
        // if (msgSender == signetor) revert Can__notfollow();
        // bool result = checkfollowed(signetor, msgSender);
        // if (result == false) revert Never__Followed();

        uint256 totalFollower = s.fm.follower[signetor].followerNum;
        uint256 i = findfollowerId(signetor, msgSender);
        if (totalFollower == i) {
            s.fm.follower[signetor].followerNum -= 1;
            s.fm.follower[signetor].whoFollowed.pop();
        } else {
            s.fm.follower[signetor].followerNum -= 1;
            s.fm.follower[signetor].whoFollowed[i - 1] = s.fm.follower[signetor].whoFollowed[
                s.fm.follower[signetor].whoFollowed.length - 1
            ];
            s.fm.follower[signetor].whoFollowed.pop();
        }

        uint256 totalFollowing = s.fm.following[msgSender].FollowingNum;
        uint256 j = findFollwingId(msgSender, signetor);
        if (totalFollowing == j) {
            s.fm.following[msgSender].FollowingNum -= 1;
            s.fm.following[msgSender].followedWho.pop();
        } else {
            s.fm.following[msgSender].FollowingNum -= 1;
            s.fm.following[msgSender].followedWho[j - 1] = s.fm.following[msgSender].followedWho[
                s.fm.following[msgSender].followedWho.length - 1
            ];
            // for (j; j < ; j++) {
            //     ;
            // }
            s.fm.following[msgSender].followedWho.pop();
        }
    }

    function like(address msgSender, uint256 SignetId, address SignetIdOwner) internal {
        AppStorage storage s = getStorage();
        // if (SignetId > s.fss.signetId || s.fss.signetId == 0 || SignetId == 0) revert Wrong__SignetId();
        // if (
        //     signetState[SignetId].SignetIdOwner == msgSender ||
        //     signetState[SignetId].SignetIdOwner != SignetIdOwner
        // ) revert Wrong__UserSubmitted();
        if (checklikeable(SignetId) == true) {
            if (
                (s.fm.signetState[SignetId].SignetIdOwner == msgSender ||
                    s.fm.signetState[SignetId].SignetIdOwner != SignetIdOwner) == false
            ) {
                if (checkliked(SignetId, msgSender) == false) {
                    s.fm.signetState[SignetId].likeNum++;
                    s.fm.signetState[SignetId].likeContributors.push(msgSender);
                }
            }
        }
    }

    function unlike(address msgSender, uint256 SignetId, address SignetIdOwner) internal {
        AppStorage storage s = getStorage();
        if (checklikeable(SignetId) == true) {
            if (
                (s.fm.signetState[SignetId].SignetIdOwner == msgSender ||
                    s.fm.signetState[SignetId].SignetIdOwner != SignetIdOwner) == false
            ) {
                if (checkliked(SignetId, msgSender) == true) {
                    uint256 totalFollower = s.fm.signetState[SignetId].likeNum;
                    uint256 i = findLikeId(SignetId, msgSender);
                    if (totalFollower == i) {
                        s.fm.signetState[SignetId].likeNum -= 1;
                        s.fm.signetState[SignetId].likeContributors.pop();
                    } else {
                        s.fm.signetState[SignetId].likeNum -= 1;
                        s.fm.signetState[SignetId].likeContributors[i - 1] = s
                            .fm
                            .signetState[SignetId]
                            .likeContributors[
                                s.fm.signetState[SignetId].likeContributors.length - 1
                            ];
                        s.fm.signetState[SignetId].likeContributors.pop();
                    }
                }
            }
        }
    }

    function star(address msgSender, address SignetIdOwner, uint256 SignetId) internal {
        AppStorage storage s = getStorage();
        s.fm.Stars[SignetIdOwner]++;
        s.fm.signetState[SignetId].starNum++;
        s.fm.signetState[SignetId].starContributors.push(msgSender);
    }

    function checklikeable(uint256 SignetId) internal view returns (bool) {
        AppStorage storage s = getStorage();
        return SignetId <= s.fss.signetId || s.fss.signetId != 0 || SignetId != 0;
    }

    function checkfollowed(
        address signetor,
        address followersaddress
    ) internal view returns (bool) {
        AppStorage storage s = getStorage();
        uint256 i;
        for (i = 0; i < s.fm.follower[signetor].whoFollowed.length; i++) {
            if (s.fm.follower[signetor].whoFollowed[i] == followersaddress) {
                return (true);
            }
        }
        return (false);
    }

    function checkliked(uint256 signetID, address likedAddress) internal view returns (bool) {
        AppStorage storage s = getStorage();
        uint256 i;
        for (i = 0; i < s.fm.signetState[signetID].likeContributors.length; i++) {
            if (s.fm.signetState[signetID].likeContributors[i] == likedAddress) {
                return (true);
            }
        }
        return (false);
    }

    function findfollowerId(
        address signetor,
        address followersaddress
    ) internal view returns (uint256 id) {
        AppStorage storage s = getStorage();
        uint256 i = 1;
        for (i = 1; i < s.fm.follower[signetor].whoFollowed.length + 1; i++) {
            if (s.fm.follower[signetor].whoFollowed[i - 1] == followersaddress) {
                return i;
            }
        }
    }

    function findFollwingId(
        address signetor,
        address followingAaddress
    ) internal view returns (uint256 id) {
        AppStorage storage s = getStorage();
        uint256 i = 1;
        for (i = 1; i < s.fm.following[signetor].followedWho.length + 1; i++) {
            if (s.fm.following[signetor].followedWho[i - 1] == followingAaddress) {
                return i;
            }
        }
    }

    function findLikeId(
        uint256 signetID,
        address likedAddress
    ) internal view returns (uint256 id) {
        AppStorage storage s = getStorage();
        uint256 i = 1;
        for (i = 1; i < s.fm.signetState[signetID].likeContributors.length + 1; i++) {
            if (s.fm.signetState[signetID].likeContributors[i - 1] == likedAddress) {
                return i;
            }
        }
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

    function getStaredNumForSignetor(address SignetorAddress) internal view returns (uint256) {
        AppStorage storage s = getStorage();
        return (s.fm.Stars[SignetorAddress]);
    }

    function getLikedNum(uint256 SignetId) internal view returns (uint256) {
        AppStorage storage s = getStorage();
        return (s.fm.signetState[SignetId].likeNum);
    }

    function getStaredNum(uint256 SignetId) internal view returns (uint256) {
        AppStorage storage s = getStorage();
        return (s.fm.signetState[SignetId].starNum);
    }

    function getStarContributor(uint256 SignetId) internal view returns (address[] memory) {
        AppStorage storage s = getStorage();
        return (s.fm.signetState[SignetId].starContributors);
    }

    function getLikeContributor(uint256 SignetId) internal view returns (address[] memory) {
        AppStorage storage s = getStorage();
        return (s.fm.signetState[SignetId].likeContributors);
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
    FollowSysStuct fss;
    Followers flwr;
    Following flwi;
    signetinfo signetinfo;
    followMap fm;
    mapSignetAddress ma;
    controllorStorage cs;
    bool locked;
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
}

struct profilemap {
    mapping(uint256 => pfpStruct) pfp;
    mapping(uint256 => nameStruct) name;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

struct FollowSysStuct {
    uint256 TotalSignetorsNum;
    uint256 signetId;
    address signetControllor;
    address owner;
    uint256 appreciateAmount;
}
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
    address SignetIdOwner;
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
pragma solidity 0.8.9;

struct controllorStorage {
    uint256 TotalSignetorsNum;
    address signetprofileSys;
    address signetFollowSys;
    bool allowTranfer;
}
struct mapSignetAddress {
    mapping(address => address) collectionContractList;
}
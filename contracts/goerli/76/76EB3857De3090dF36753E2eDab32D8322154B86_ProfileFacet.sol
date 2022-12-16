// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./libraries/LibDiamond.sol";
import "./libraries/LibSignetStorage.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
/*
 * @title Signet Profile Facet
 * @author https://outerspace.ai/
 */
error name__IsTooLong();
error name__IsNotAvalable();
error no__NameCreated();
error name__Created();
error No__ContractCreated();
error Not_Owner();
error Wrong__Type();

contract ProfileFacet {
    AppStorage s;

    modifier onlyOwner() {
        address _owner = LibDiamond.contractOwner();
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
        if (LibSignetStorage.getOwnerNumContractOfSignetor(msg.sender) == 0)
            revert No__ContractCreated();
        _;
    }
    event ProfileUpdated(address indexed messageSender, string indexed _name, string indexed _pfp);

    function hasName(address signetUserAddress) public view returns (bool) {
        return (LibSignetStorage.hasName(signetUserAddress));
    }

    function checkName(address signetUserAddress) public view returns (string memory) {
        return (LibSignetStorage.checkName(signetUserAddress));
    }

    function checkNameAvalable(string memory _name) public view returns (bool) {
        return (LibSignetStorage.checkNameAvalable(_name));
    }

    function checkNameAddress(string memory _name) public view returns (bool, address) {
        return (LibSignetStorage.checkNameAddress(_name));
    }

    function modifyNameForUser(string memory _newname) external Registered {
        if (bytes(_newname).length > 15) revert name__IsTooLong();
        if (checkNameAvalable(_newname) == false) revert name__IsNotAvalable();
        LibSignetStorage.modifyNameForUser(_newname, msg.sender);
        emit ProfileUpdated(msg.sender, _newname, "");
    }

    function hasPfp(address signetUserAddress) public view returns (bool) {
        return (LibSignetStorage.hasPfp(signetUserAddress));
    }

    function checkPfp(address signetUserAddress) public view returns (string memory) {
        (string memory a, address b, uint256 c, uint256 d) = LibSignetStorage.checkPfp(
            signetUserAddress
        );
        if (d == 721) {
            if (IERC721(b).ownerOf(c) == signetUserAddress) {
                return a;
            } else {
                return
                    "You seeing this message is becuase this address don't have any pfp created!";
            }
        } else if (d == 1155) {
            if (IERC1155(b).balanceOf(signetUserAddress, c) != 0) {
                return a;
            } else {
                return
                    "You seeing this message is becuase this address don't have any pfp created!";
            }
        } else {
            return "You seeing this message is becuase this address don't have any pfp created!";
        }
    }

    function modifyPfpForUser(
        string memory _pfp,
        address _collection,
        uint256 _tokenId,
        uint256 _typeOf
    ) external Registered {
        if (_typeOf != 721 && _typeOf != 1155) revert Wrong__Type();
        if (_typeOf == 721) {
            if (IERC721(_collection).ownerOf(_tokenId) == msg.sender) {
                LibSignetStorage.modifyPfpForUser(
                    _pfp,
                    msg.sender,
                    _tokenId,
                    _collection,
                    _typeOf
                );
                emit ProfileUpdated(msg.sender, "", _pfp);
            }
        }
        if (_typeOf == 1155) {
            if (IERC1155(_collection).balanceOf(msg.sender, _tokenId) > 0) {
                LibSignetStorage.modifyPfpForUser(
                    _pfp,
                    msg.sender,
                    _tokenId,
                    _collection,
                    _typeOf
                );
                emit ProfileUpdated(msg.sender, "", _pfp);
            }
        }
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

    function getAllowedTranfer() internal view returns (bool) {
        AppStorage storage s = getStorage();
        return (s.cs.allowTranfer);
    }

    function setAllowedTranfer(bool _allowedTranfer) internal {
        AppStorage storage s = getStorage();
        s.cs.allowTranfer = _allowedTranfer;
    }

    function createSignetor(address newContractAddress, address creator) internal {
        AppStorage storage s = getStorage();
        s.ma.s_creatorCollection[creator].numOfCollectionCreated++;
        crators memory Crators = crators(creator, newContractAddress, 1);
        s.ma.s_creatorCollection[creator].collectionCreated.push(Crators);
    }

    function getValueForSendMessage() internal view returns (uint256) {
        AppStorage storage s = getStorage();
        return (s.ss.messagePrice);
    }

    function setValueForSendMessage(uint256 _messagePrice) internal {
        AppStorage storage s = getStorage();
        s.ss.messagePrice = _messagePrice;
    }

    function getContractDetails(
        uint256 noOfContract,
        address contractOwner
    ) internal view returns (address, address, uint256) {
        AppStorage storage s = getStorage();
        address a = s
            .ma
            .s_creatorCollection[contractOwner]
            .collectionCreated[noOfContract]
            .Creator;
        address b = s
            .ma
            .s_creatorCollection[contractOwner]
            .collectionCreated[noOfContract]
            .Contract;
        uint256 c = s
            .ma
            .s_creatorCollection[contractOwner]
            .collectionCreated[noOfContract]
            .collectiontype;
        return (a, b, c);
    }

    function getOwnerNumContractOfSignetor(address contractOwner) internal view returns (uint256) {
        AppStorage storage s = getStorage();
        uint256 a = s.ma.s_creatorCollection[contractOwner].numOfCollectionCreated;
        return a;
    }

    function controllorCreateSignetor(address msgSender, address _b) internal {
        AppStorage storage s = getStorage();
        s.cs.TotalSignetorsNum++;
        s.ma.collectionContractList[_b] = msgSender;
    }

    function getTotalSignetorNum() internal view returns (uint256) {
        AppStorage storage s = getStorage();
        return (s.cs.TotalSignetorsNum);
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

    function checkNameAddress(string memory _name) internal view returns (bool, address) {
        AppStorage storage s = getStorage();
        for (uint256 i = 0; i < s.ps.totalName + 1; i++) {
            if (
                keccak256(abi.encodePacked(s.pm.name[i].name)) ==
                keccak256(abi.encodePacked(_name))
            ) {
                return (true, s.pm.name[i].owner);
            }
        }
        return (false, address(0));
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

    function checkPfp(
        address _signetUserAddress
    ) internal view returns (string memory, address, uint256, uint256) {
        AppStorage storage s = getStorage();
        for (uint256 i = 0; i < s.ps.totalpfp + 1; i++) {
            if (s.pm.pfp[i].owner == _signetUserAddress) {
                return (
                    s.pm.pfp[i].pfp,
                    s.pm.pfp[i].collection,
                    s.pm.pfp[i].tokenId,
                    s.pm.pfp[i].typeOf
                );
            }
        }
        return (
            "You seeing this message is becuase this address don't have any pfp created!",
            address(0),
            0,
            0
        );
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

    function modifyPfpForUser(
        string memory _pfp,
        address _signetUserAddress,
        uint256 _tokenId,
        address _collection,
        uint256 _typeOf
    ) internal {
        AppStorage storage s = getStorage();
        if (hasPfp(_signetUserAddress) == false) {
            s.ps.totalpfp++;
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
            s.pm.pfp[oldPfpId].tokenId = _tokenId;
            s.pm.pfp[oldPfpId].collection = _collection;
            s.pm.pfp[oldPfpId].typeOf = _typeOf;
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
        s.fm.follower[signetor].followerNum++;
        s.fm.follower[signetor].whoFollowed.push(msgSender);
        s.fm.following[msgSender].FollowingNum++;
        s.fm.following[msgSender].followedWho.push(signetor);
    }

    function unfollow(address msgSender, address signetor) internal {
        AppStorage storage s = getStorage();

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

    function like(address msgSender, uint256 SignetId) internal {
        AppStorage storage s = getStorage();
        s.fm.signetState[SignetId].likeNum++;
        s.fm.signetState[SignetId].likeContributors.push(msgSender);
    }

    function unlike(address msgSender, uint256 SignetId) internal {
        AppStorage storage s = getStorage();

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
                .likeContributors[s.fm.signetState[SignetId].likeContributors.length - 1];
            s.fm.signetState[SignetId].likeContributors.pop();
        }
    }

    function star(address msgSender, address SignetIdOwner, uint256 SignetId) internal {
        AppStorage storage s = getStorage();
        s.fm.Stars[SignetIdOwner]++;
        s.fm.signetState[SignetId].starNum++;
        s.fm.signetState[SignetId].starContributors.push(msgSender);
    }

    function setAppreciateAmount(uint256 _amount) internal {
        AppStorage storage s = getStorage();
        s.fss.appreciateAmount = _amount;
    }

    function getAppreciateAmount() internal view returns (uint256) {
        AppStorage storage s = getStorage();
        return (s.fss.appreciateAmount);
    }

    function setStarCommission(uint256 _starCommisionPercent) internal {
        AppStorage storage s = getStorage();
        s.ss.commission = _starCommisionPercent;
    }

    function getStarCommission() internal view returns (uint256) {
        AppStorage storage s = getStorage();
        return (s.ss.commission);
    }

    function checklikeable(
        address SignetIdOwner,
        uint256 SignetId
    ) internal view returns (bool result) {
        AppStorage storage s = getStorage();
        if (SignetId <= s.fss.signetId) {
            if (s.fss.signetId != 0) {
                if (SignetId != 0) {
                    if (s.fm.signetState[SignetId].SignetIdOwner == SignetIdOwner) {
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

    function getSignetId() internal view returns (uint256) {
        AppStorage storage s = getStorage();
        return (s.fss.signetId);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

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
import "./SignetStorage.sol";

struct AppStorage {
    SignetStorage ss;
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
    uint256 TotalSignetorsNum;
    address signetprofileSys;
    address signetFollowSys;
    bool allowTranfer;
}
struct mapSignetAddress {
    mapping(address => address) collectionContractList;
    mapping(address => creatorCollection) s_creatorCollection;
}
struct creatorCollection {
    uint256 numOfCollectionCreated;
    crators[] collectionCreated;
}

struct crators {
    address Creator;
    address Contract;
    uint8 collectiontype;
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

import "./ProfileSysStorage.sol";
import "./FollowSysStorage.sol";
import "./ControllorStorage.sol";

struct SignetStorage {
    uint256 commission;
    uint256 messagePrice;
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
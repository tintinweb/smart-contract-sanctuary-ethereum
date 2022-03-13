//SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./IERC721.sol";

contract Seaport is Ownable {
    using SafeMath for uint256;
    using Address for address;

    event LockAsset(
        address indexed assetAddress,
        address indexed ownerAddress,
        uint256 tokenId
    );

    enum Status {
        None,
        Locked,
        Unlocked,
        Burn
    }

    struct Asset {
        address contractAddress;
        uint256 tokenId;
        address ownerAddress;
        uint256 lockDate;
        Status status;
    }

    struct UnlockAsset {
        address contractAddress;
        uint256 tokenId;
        address toAddress;
    }

    struct LockAssetArgs {
        address contractAddress;
        uint256 tokenId;
    }

    struct BurnAsset {
        address contractAddress;
        uint256 tokenId;
    }

    mapping(bytes32 => Asset) _assets;
    bool _isWhiteListAssetAllow;
    mapping(address => bool) _allowAssets;

    constructor(bool isWhiteListAssetAllow) {
        _isWhiteListAssetAllow = isWhiteListAssetAllow;
    }

    function getIsWhiteListAssetAllow() public view returns (bool) {
        return _isWhiteListAssetAllow;
    }

    function setIsWhiteListAssetAllow(bool isWhiteListAssetAllow)
        external
        onlyOwner
        returns (bool)
    {
        _isWhiteListAssetAllow = isWhiteListAssetAllow;
        return _isWhiteListAssetAllow;
    }

    function getAllowAsset(address assetAddress) public view returns (bool) {
        return _allowAssets[assetAddress];
    }

    function setAllowAsset(address assetAddress, bool assetStatus)
        external
        onlyOwner
        returns (bool)
    {
        if (!assetAddress.isContract()) {
            revert("address is not contract address");
        }

        _allowAssets[assetAddress] = assetStatus;

        return _allowAssets[assetAddress];
    }

    function getAsset(address assetAddress, uint256 tokenId)
        public
        view
        returns (Asset memory)
    {
        bytes32 uniqueKey = getPrivateUniqueKey(assetAddress, tokenId);

        return _assets[uniqueKey];
    }

    function lockAsset(address assetAddress, uint256 tokenId)
        external
    {
        if (!assetAddress.isContract()) {
            revert("address is not contract address");
        }

        if (_isWhiteListAssetAllow && !_allowAssets[assetAddress]) {
            revert("address is not allow");
        }

        bytes32 uniqueKey = getPrivateUniqueKey(assetAddress, tokenId);

        if (_assets[uniqueKey].status == Status.Locked) {
            revert("Asset is locked");
        }

        IERC721 erc721 = IERC721(assetAddress);

        if (msg.sender != erc721.ownerOf(tokenId)) {
            revert("not a valid owner");
        }

        erc721.transferFrom(msg.sender, address(this), tokenId);

        _assets[uniqueKey].contractAddress = assetAddress;
        _assets[uniqueKey].tokenId = tokenId;
        _assets[uniqueKey].ownerAddress = msg.sender;
        _assets[uniqueKey].lockDate = getDateTimeNowInSeconds();
        _assets[uniqueKey].status = Status.Locked;

        emit LockAsset(assetAddress, msg.sender, tokenId);
    }

    function lockAssets(LockAssetArgs[] memory assets)
        external
    {
        if (assets.length == 0) {
            revert("assets lenght should be grater then 0");
        }

        for (uint256 i = 0; i < assets.length; i++) {
            if (!assets[i].contractAddress.isContract()) {
                revert("address is not contract address");
            }

            if (_isWhiteListAssetAllow && !_allowAssets[assets[i].contractAddress]) {
                revert("address is not allow");
            }

            bytes32 uniqueKey = getPrivateUniqueKey(assets[i].contractAddress, assets[i].tokenId);

            if (_assets[uniqueKey].status == Status.Locked) {
                revert("Asset is locked");
            }

            IERC721 erc721 = IERC721(assets[i].contractAddress);

            if (msg.sender != erc721.ownerOf(assets[i].tokenId)) {
                revert("not a valid owner");
            }
        }

        for (uint256 i = 0; i < assets.length; i++) {
            bytes32 uniqueKey = getPrivateUniqueKey(assets[i].contractAddress, assets[i].tokenId);

            IERC721 erc721 = IERC721(assets[i].contractAddress);

            erc721.transferFrom(msg.sender, address(this), assets[i].tokenId);

            _assets[uniqueKey].contractAddress = assets[i].contractAddress;
            _assets[uniqueKey].tokenId = assets[i].tokenId;
            _assets[uniqueKey].ownerAddress = msg.sender;
            _assets[uniqueKey].lockDate = getDateTimeNowInSeconds();
            _assets[uniqueKey].status = Status.Locked;

            emit LockAsset(assets[i].contractAddress, msg.sender, assets[i].tokenId);
        }
    }


    function getPrivateUniqueKey(address assetAddress, uint256 tokenId)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(assetAddress, tokenId));
    }

    function getDateTimeNowInSeconds() private view returns (uint256) {
        return block.timestamp;
    }

    function unlockAsset(
        address assetAddress,
        uint256 tokenId,
        address toAddress
    ) external onlyOwner {
        if (!assetAddress.isContract()) {
            revert("address is not contract address");
        }

        if (_isWhiteListAssetAllow && !_allowAssets[assetAddress]) {
            revert("address is not allow");
        }

        bytes32 uniqueKey = getPrivateUniqueKey(assetAddress, tokenId);

        if (_assets[uniqueKey].status != Status.Locked) {
            revert("Asset is not locked");
        }

        IERC721 erc721 = IERC721(assetAddress);

        if (address(this) != erc721.ownerOf(tokenId)) {
            revert("not a valid owner");
        }

        erc721.transferFrom(address(this), toAddress, tokenId);

        _assets[uniqueKey].ownerAddress = toAddress;
        _assets[uniqueKey].status = Status.Unlocked;
    }

    function unlockAssets(UnlockAsset[] memory assets) external onlyOwner {
        if (assets.length == 0) {
            revert("assets lenght should be grater then 0");
        }

        for (uint256 i = 0; i < assets.length; i++) {
            if (!assets[i].contractAddress.isContract()) {
                revert("address is not contract address");
            }

            if (
                _isWhiteListAssetAllow &&
                !_allowAssets[assets[i].contractAddress]
            ) {
                revert("address is not allow");
            }

            bytes32 uniqueKey = getPrivateUniqueKey(
                assets[i].contractAddress,
                assets[i].tokenId
            );

            if (_assets[uniqueKey].status != Status.Locked) {
                revert("Asset is not locked");
            }

            IERC721 erc721 = IERC721(assets[i].contractAddress);

            if (address(this) != erc721.ownerOf(assets[i].tokenId)) {
                revert("not a valid owner");
            }
        }

        for (uint256 i = 0; i < assets.length; i++) {
            IERC721 erc721 = IERC721(assets[i].contractAddress);

            erc721.transferFrom(
                address(this),
                assets[i].toAddress,
                assets[i].tokenId
            );

            bytes32 uniqueKey = getPrivateUniqueKey(
                assets[i].contractAddress,
                assets[i].tokenId
            );

            _assets[uniqueKey].ownerAddress = assets[i].toAddress;
            _assets[uniqueKey].status = Status.Unlocked;
        }
    }

    function burnAsset(address assetAddress, uint256 tokenId)
        external
        onlyOwner
    {
        if (!assetAddress.isContract()) {
            revert("address is not contract address");
        }

        if (_isWhiteListAssetAllow && !_allowAssets[assetAddress]) {
            revert("address is not allow");
        }

        bytes32 uniqueKey = getPrivateUniqueKey(assetAddress, tokenId);

        if (_assets[uniqueKey].status != Status.Locked) {
            revert("Asset is not locked");
        }

        IERC721 erc721 = IERC721(assetAddress);

        if (address(this) != erc721.ownerOf(tokenId)) {
            revert("not a valid owner");
        }

        erc721.burn(tokenId);

        _assets[uniqueKey].status = Status.Burn;
    }

    function burnAssets(BurnAsset[] memory assets) external onlyOwner {
        if (assets.length == 0) {
            revert("assets lenght should be grater then 0");
        }

        for (uint256 i = 0; i < assets.length; i++) {
            if (!assets[i].contractAddress.isContract()) {
                revert("address is not contract address");
            }

            if (
                _isWhiteListAssetAllow &&
                !_allowAssets[assets[i].contractAddress]
            ) {
                revert("address is not allow");
            }

            bytes32 uniqueKey = getPrivateUniqueKey(
                assets[i].contractAddress,
                assets[i].tokenId
            );

            if (_assets[uniqueKey].status != Status.Locked) {
                revert("Asset is not locked");
            }

            IERC721 erc721 = IERC721(assets[i].contractAddress);

            if (address(this) != erc721.ownerOf(assets[i].tokenId)) {
                revert("not a valid owner");
            }
        }

        for (uint256 i = 0; i < assets.length; i++) {
            IERC721 erc721 = IERC721(assets[i].contractAddress);

            erc721.burn(assets[i].tokenId);

            bytes32 uniqueKey = getPrivateUniqueKey(
                assets[i].contractAddress,
                assets[i].tokenId
            );

            _assets[uniqueKey].status = Status.Burn;
        }
    }
}
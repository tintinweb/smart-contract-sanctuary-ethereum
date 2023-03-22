// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.9;

import "./openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/ICapsule.sol";
import "./CapsuleMinterStorage.sol";
import "./access/Governable.sol";
import "./Errors.sol";

contract CapsuleMinter is
    Initializable,
    Governable,
    ReentrancyGuard,
    IERC721Receiver,
    ERC1155Holder,
    CapsuleMinterStorageV3
{
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    string public constant VERSION = "1.2.0";
    uint256 public constant TOKEN_TYPE_LIMIT = 100;
    uint256 internal constant MAX_CAPSULE_MINT_TAX = 0.1 ether;

    event AddedToWhitelist(address indexed user);
    event RemovedFromWhitelist(address indexed user);
    event FlushedTaxAmount(uint256 taxAmount);
    event CapsuleMintTaxUpdated(uint256 oldMintTax, uint256 newMintTax);
    event UpdatedWhitelistedCallers(address indexed caller);
    event SimpleCapsuleMinted(address indexed account, address indexed capsule, uint256 capsuleId);
    event SimpleCapsuleBurnt(address indexed account, address indexed capsule, uint256 capsuleId);
    event SingleERC20CapsuleMinted(
        address indexed account,
        address indexed capsule,
        address indexed token,
        uint256 amount,
        uint256 capsuleId
    );
    event SingleERC20CapsuleBurnt(
        address indexed account,
        address indexed capsule,
        address indexed token,
        uint256 amount,
        uint256 capsuleId
    );
    event SingleERC721CapsuleMinted(
        address indexed account,
        address indexed capsule,
        address indexed token,
        uint256 id,
        uint256 capsuleId
    );
    event SingleERC721CapsuleBurnt(
        address indexed account,
        address indexed capsule,
        address indexed token,
        uint256 id,
        uint256 capsuleId
    );

    event MultiERC20CapsuleMinted(
        address indexed account,
        address indexed capsule,
        address[] tokens,
        uint256[] amounts,
        uint256 capsuleId
    );
    event MultiERC20CapsuleBurnt(
        address indexed account,
        address indexed capsule,
        address[] tokens,
        uint256[] amounts,
        uint256 capsuleId
    );
    event MultiERC721CapsuleMinted(
        address indexed account,
        address indexed capsule,
        address[] tokens,
        uint256[] ids,
        uint256 capsuleId
    );
    event MultiERC721CapsuleBurnt(
        address indexed account,
        address indexed capsule,
        address[] tokens,
        uint256[] ids,
        uint256 capsuleId
    );

    event MultiERC1155CapsuleMinted(
        address indexed account,
        address indexed capsule,
        address[] tokens,
        uint256[] ids,
        uint256[] amounts,
        uint256 capsuleId
    );
    event MultiERC1155CapsuleBurnt(
        address indexed account,
        address indexed capsule,
        address[] tokens,
        uint256[] ids,
        uint256[] amounts,
        uint256 capsuleId
    );

    function initialize(address _factory) external initializer {
        require(_factory != address(0), Errors.ZERO_ADDRESS);
        __Governable_init();
        factory = ICapsuleFactory(_factory);
        capsuleMintTax = 0.001 ether;
    }

    modifier checkTaxRequirement() {
        if (!mintWhitelist.contains(_msgSender())) {
            require(msg.value == capsuleMintTax, Errors.INCORRECT_TAX_AMOUNT);
        }
        _;
    }

    /// @dev Using internal function to decrease contract file size.
    modifier sanityChecks(address _capsule, address _burnFrom) {
        _sanityChecks(_capsule, _burnFrom);
        _;
    }

    modifier onlyCollectionMinter(address _capsule) {
        require(factory.isCapsule(_capsule), Errors.NOT_CAPSULE);
        require(ICapsule(_capsule).isCollectionMinter(_msgSender()), Errors.NOT_COLLECTION_MINTER);
        _;
    }

    /******************************************************************************
     *                              Read functions                                *
     *****************************************************************************/

    // return the owner of a Capsule by id
    function getCapsuleOwner(address _capsule, uint256 _id) external view returns (address) {
        return ICapsule(_capsule).ownerOf(_id);
    }

    /// @notice Get list of mint whitelisted address
    function getMintWhitelist() external view returns (address[] memory) {
        return mintWhitelist.values();
    }

    /// @notice Get list of whitelisted caller address
    function getWhitelistedCallers() external view returns (address[] memory) {
        return whitelistedCallers.values();
    }

    /// @notice Return whether given address is whitelisted caller or not
    function isWhitelistedCaller(address _caller) external view returns (bool) {
        return whitelistedCallers.contains(_caller);
    }

    function multiERC20Capsule(address _capsule, uint256 _id) external view returns (MultiERC20Capsule memory _data) {
        return _multiERC20Capsule[_capsule][_id];
    }

    function multiERC721Capsule(address _capsule, uint256 _id) external view returns (MultiERC721Capsule memory _data) {
        return _multiERC721Capsule[_capsule][_id];
    }

    function multiERC1155Capsule(
        address _capsule,
        uint256 _id
    ) external view returns (MultiERC1155Capsule memory _data) {
        return _multiERC1155Capsule[_capsule][_id];
    }

    /// @notice Return whether given address is mint whitelisted or not
    function isMintWhitelisted(address _user) external view returns (bool) {
        return mintWhitelist.contains(_user);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        // `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
        return 0x150b7a02;
    }

    // ERC1155 Receiving occurs in the ERC1155Holder contract

    /******************************************************************************
     *                             Write functions                                *
     *****************************************************************************/
    function mintSimpleCapsule(
        address _capsule,
        string calldata _uri,
        address _receiver
    ) external payable nonReentrant onlyCollectionMinter(_capsule) checkTaxRequirement {
        // Mark id as a simple NFT
        uint256 _capsuleId = ICapsule(_capsule).counter();
        isSimpleCapsule[_capsule][_capsuleId] = true;
        ICapsule(_capsule).mint(_receiver, _uri);
        emit SimpleCapsuleMinted(_receiver, _capsule, _capsuleId);
    }

    function burnSimpleCapsule(
        address _capsule,
        uint256 _capsuleId,
        address _burnFrom
    ) external nonReentrant sanityChecks(_capsule, _burnFrom) {
        require(isSimpleCapsule[_capsule][_capsuleId], Errors.NOT_SIMPLE_CAPSULE);
        delete isSimpleCapsule[_capsule][_capsuleId];
        // We do not have to store the token uri in a local variable - we are emitting an event before burn
        emit SimpleCapsuleBurnt(_burnFrom, _capsule, _capsuleId);
        ICapsule(_capsule).burn(_burnFrom, _capsuleId);
    }

    function mintSingleERC20Capsule(
        address _capsule,
        address _token,
        uint256 _amount,
        string calldata _uri,
        address _receiver
    ) external payable nonReentrant onlyCollectionMinter(_capsule) checkTaxRequirement {
        require(_amount > 0, Errors.INVALID_TOKEN_AMOUNT);
        require(_token != address(0), Errors.INVALID_TOKEN_ADDRESS);

        // get the current top counter
        uint256 _capsuleId = ICapsule(_capsule).counter();

        // transfer tokens from caller to contracts
        if (!whitelistedCallers.contains(_msgSender())) {
            // overwrite _amount
            _amount = _depositToken(IERC20(_token), _msgSender(), _amount);
        }

        // then, add user data into the contract (tie NFT to value):
        // - set the ID of the Capsule NFT at counter to map to the passed in tokenAddress
        // - set the ID of the Capsule NFT at counter to map to the passed in tokenAmount
        singleERC20Capsule[_capsule][_capsuleId].tokenAddress = _token;
        singleERC20Capsule[_capsule][_capsuleId].tokenAmount = _amount;
        // lastly, mint the Capsule NFT (minted at the current counter (obtained above as id))
        ICapsule(_capsule).mint(_receiver, _uri);

        emit SingleERC20CapsuleMinted(_receiver, _capsule, _token, _amount, _capsuleId);
    }

    function burnSingleERC20Capsule(
        address _capsule,
        uint256 _capsuleId,
        address _burnFrom,
        address _receiver
    ) public nonReentrant sanityChecks(_capsule, _burnFrom) {
        // get the amount of tokens held by the Capsule NFT id
        uint256 tokensHeldById = singleERC20Capsule[_capsule][_capsuleId].tokenAmount;
        // If there is no token amount in stored data then provided id is not ERC20 Capsule id
        require(tokensHeldById > 0, Errors.NOT_ERC20_CAPSULE_ID);

        // get the token address held at the Capsule NFT id
        address heldTokenAddress = singleERC20Capsule[_capsule][_capsuleId].tokenAddress;
        // then, delete the Capsule NFT data at id
        delete singleERC20Capsule[_capsule][_capsuleId];

        // burn the Capsule NFT at id
        ICapsule(_capsule).burn(_burnFrom, _capsuleId);

        // send tokens back to the user
        IERC20(heldTokenAddress).safeTransfer(_receiver, tokensHeldById);
        emit SingleERC20CapsuleBurnt(_burnFrom, _capsule, heldTokenAddress, tokensHeldById, _capsuleId);
    }

    function mintSingleERC721Capsule(
        address _capsule,
        address _token,
        uint256 _id,
        string calldata _uri,
        address _receiver
    ) external payable nonReentrant onlyCollectionMinter(_capsule) checkTaxRequirement {
        // get the current top counter
        uint256 _capsuleId = ICapsule(_capsule).counter();

        if (!whitelistedCallers.contains(_msgSender())) {
            // transfer input NFT to contract. safeTransferFrom does check that from, _msgSender in this case, is owner.
            IERC721(_token).safeTransferFrom(_msgSender(), address(this), _id);
            // check that the contract owns that NFT
            require(IERC721(_token).ownerOf(_id) == address(this), Errors.NOT_NFT_OWNER);
        }

        // then, add user data into the contract (tie Capsule NFT to input token):
        // - set the ID of the Capsule NFT at counter to map to the passed in tokenAddress
        // - set the ID of the Capsule NFT at counter to map to the passed in id
        singleERC721Capsule[_capsule][_capsuleId].tokenAddress = _token;
        singleERC721Capsule[_capsule][_capsuleId].id = _id;
        // lastly, mint the Capsule NFT
        ICapsule(_capsule).mint(_receiver, _uri);

        emit SingleERC721CapsuleMinted(_receiver, _capsule, _token, _id, _capsuleId);
    }

    function burnSingleERC721Capsule(
        address _capsule,
        uint256 _capsuleId,
        address _burnFrom,
        address _receiver
    ) public nonReentrant sanityChecks(_capsule, _burnFrom) {
        // get the token address held at the Capsule NFT id
        address heldTokenAddress = singleERC721Capsule[_capsule][_capsuleId].tokenAddress;
        // If there is no token address in stored data then provided id is not ERC721 Capsule id
        require(heldTokenAddress != address(0), Errors.NOT_ERC721_CAPSULE_ID);
        // get the amount of token Id held by the Capsule NFT id
        uint256 tokenId = singleERC721Capsule[_capsule][_capsuleId].id;
        // then, delete the Capsule NFT data at id
        delete singleERC721Capsule[_capsule][_capsuleId];

        // burn the Capsule NFT
        ICapsule(_capsule).burn(_burnFrom, _capsuleId);
        // send token back to the user
        IERC721(heldTokenAddress).safeTransferFrom(address(this), _receiver, tokenId);

        emit SingleERC721CapsuleBurnt(_burnFrom, _capsule, heldTokenAddress, tokenId, _capsuleId);
    }

    function mintMultiERC20Capsule(
        address _capsule,
        address[] calldata _tokens,
        uint256[] calldata _amounts,
        string calldata _uri,
        address _receiver
    ) external payable nonReentrant onlyCollectionMinter(_capsule) checkTaxRequirement {
        uint256 _len = _tokens.length;

        require(_len > 0 && _len <= TOKEN_TYPE_LIMIT, Errors.INVALID_TOKEN_ARRAY_LENGTH);
        require(_len == _amounts.length, Errors.LENGTH_MISMATCH);

        // get the current top counter
        uint256 _capsuleId = ICapsule(_capsule).counter();

        _multiERC20Capsule[_capsule][_capsuleId].tokenAddresses = _tokens;
        if (whitelistedCallers.contains(_msgSender())) {
            _multiERC20Capsule[_capsule][_capsuleId].tokenAmounts = _amounts;
            emit MultiERC20CapsuleMinted(_receiver, _capsule, _tokens, _amounts, _capsuleId);
        } else {
            // Some tokens, like USDT, may have a transfer fee, so we want to record actual transfer amount
            uint256[] memory _actualAmounts = new uint256[](_len);
            // loop assumes that the token address and amount is mapped to the same index in both arrays
            // meaning: the user is sending _amounts[0] of _tokens[0]
            for (uint256 i; i < _len; i++) {
                address _token = _tokens[i];
                uint256 _amount = _amounts[i];

                require(_amount > 0, Errors.INVALID_TOKEN_AMOUNT);
                require(_token != address(0), Errors.INVALID_TOKEN_ADDRESS);

                // transfer tokens from caller to contract
                _actualAmounts[i] = _depositToken(IERC20(_token), _msgSender(), _amount);
            }

            // then add user data into the contract (tie Capsule NFT to input):
            _multiERC20Capsule[_capsule][_capsuleId].tokenAmounts = _actualAmounts;
            emit MultiERC20CapsuleMinted(_receiver, _capsule, _tokens, _actualAmounts, _capsuleId);
        }
        // lastly, mint the Capsule NFT
        ICapsule(_capsule).mint(_receiver, _uri);
    }

    function burnMultiERC20Capsule(
        address _capsule,
        uint256 _capsuleId,
        address _burnFrom,
        address _receiver
    ) public nonReentrant sanityChecks(_capsule, _burnFrom) {
        address[] memory tokens = _multiERC20Capsule[_capsule][_capsuleId].tokenAddresses;
        uint256[] memory amounts = _multiERC20Capsule[_capsule][_capsuleId].tokenAmounts;
        // If there is no tokens in stored data then provided id is not ERC20 Capsule id
        require(tokens.length > 0, Errors.NOT_ERC20_CAPSULE_ID);

        // then, delete the Capsule NFT data at id
        delete _multiERC20Capsule[_capsule][_capsuleId];

        // burn the Capsule NFT
        ICapsule(_capsule).burn(_burnFrom, _capsuleId);

        for (uint256 i; i < tokens.length; i++) {
            // send tokens to the _receiver
            IERC20(tokens[i]).safeTransfer(_receiver, amounts[i]);
        }

        emit MultiERC20CapsuleBurnt(_burnFrom, _capsule, tokens, amounts, _capsuleId);
    }

    function mintMultiERC721Capsule(
        address _capsule,
        address[] calldata _tokens,
        uint256[] calldata _ids,
        string calldata _uri,
        address _receiver
    ) external payable nonReentrant onlyCollectionMinter(_capsule) checkTaxRequirement {
        uint256 _len = _tokens.length;

        require(_len > 0 && _len <= TOKEN_TYPE_LIMIT, Errors.INVALID_TOKEN_ARRAY_LENGTH);
        require(_len == _ids.length, Errors.LENGTH_MISMATCH);

        // get the current top counter
        uint256 _capsuleId = ICapsule(_capsule).counter();

        if (!whitelistedCallers.contains(_msgSender())) {
            // loop assumes that the token address and id are mapped to the same index in both arrays
            // meaning: the user is sending _ids[0] of _tokens[0]
            for (uint256 i; i < _len; i++) {
                address _token = _tokens[i];
                uint256 _id = _ids[i];

                // no require check necessary for id
                require(_token != address(0), Errors.INVALID_TOKEN_ADDRESS);

                // transfer token to contract, safeTransferFrom does check from is the owner of id
                IERC721(_token).safeTransferFrom(_msgSender(), address(this), _id);

                // check the contract owns that NFT
                require(IERC721(_token).ownerOf(_id) == address(this), Errors.NOT_NFT_OWNER);
            }
        }
        // then, add user data into the contract (tie Capsule NFT to input):
        // - set the ID of the NFT (counter) to map to the passed in tokenAddresses
        // - set the ID of the NFT (counter) to map to the passed in ids
        _multiERC721Capsule[_capsule][_capsuleId].tokenAddresses = _tokens;
        _multiERC721Capsule[_capsule][_capsuleId].ids = _ids;

        // lastly, mint the Capsule NFT
        ICapsule(_capsule).mint(_receiver, _uri);

        emit MultiERC721CapsuleMinted(_receiver, _capsule, _tokens, _ids, _capsuleId);
    }

    function burnMultiERC721Capsule(
        address _capsule,
        uint256 _capsuleId,
        address _burnFrom,
        address _receiver
    ) public nonReentrant sanityChecks(_capsule, _burnFrom) {
        address[] memory tokens = _multiERC721Capsule[_capsule][_capsuleId].tokenAddresses;
        uint256[] memory ids = _multiERC721Capsule[_capsule][_capsuleId].ids;
        // If there is no tokens in stored data then provided id is not ERC721 Capsule id
        require(tokens.length > 0, Errors.NOT_ERC721_CAPSULE_ID);

        // then, delete the Capsule NFT data at id
        delete _multiERC721Capsule[_capsule][_capsuleId];

        // burn the Capsule NFT
        ICapsule(_capsule).burn(_burnFrom, _capsuleId);

        for (uint256 i; i < tokens.length; i++) {
            // send tokens to the _receiver
            IERC721(tokens[i]).safeTransferFrom(address(this), _receiver, ids[i]);
        }

        emit MultiERC721CapsuleBurnt(_burnFrom, _capsule, tokens, ids, _capsuleId);
    }

    function mintMultiERC1155Capsule(
        address _capsule,
        address[] calldata _tokens,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        string calldata _uri,
        address _receiver
    ) external payable nonReentrant onlyCollectionMinter(_capsule) checkTaxRequirement {
        uint256 _len = _tokens.length;
        require(_len > 0 && _len <= TOKEN_TYPE_LIMIT, Errors.INVALID_TOKEN_ARRAY_LENGTH);
        require(_len == _ids.length && _len == _amounts.length, Errors.LENGTH_MISMATCH);

        if (!whitelistedCallers.contains(_msgSender())) {
            // loop assumes that the token address, id and amount are mapped to the same index in both arrays
            // meaning: the user is sending _amounts[0] of _tokens[0] at _ids[0]
            for (uint256 i; i < _len; i++) {
                address _token = _tokens[i];
                uint256 _id = _ids[i];

                // no require check necessary for id
                require(_token != address(0), Errors.INVALID_TOKEN_ADDRESS);
                uint256 _balanceBefore = IERC1155(_token).balanceOf(address(this), _id);
                // transfer token to contract, safeTransferFrom does check from is the owner of id
                IERC1155(_token).safeTransferFrom(_msgSender(), address(this), _id, _amounts[i], "");

                // check that this contract owns the ERC-1155 token
                require(
                    IERC1155(_token).balanceOf(address(this), _id) == _balanceBefore + _amounts[i],
                    Errors.NOT_NFT_OWNER
                );
            }
        }

        uint256 _capsuleId = ICapsule(_capsule).counter();
        // then, add user data into the contract (tie Capsule NFT to input):
        // - set the ID of the NFT (counter) to map to the passed in tokenAddresses
        // - set the ID of the NFT (counter) to map to the passed in ids
        // - set the ID of the NFT (counter) to map to the passed in amounts (1155)
        _multiERC1155Capsule[_capsule][_capsuleId] = MultiERC1155Capsule({
            tokenAddresses: _tokens,
            ids: _ids,
            tokenAmounts: _amounts
        });

        // lastly, mint the Capsule NFT
        ICapsule(_capsule).mint(_receiver, _uri);
        emit MultiERC1155CapsuleMinted(_receiver, _capsule, _tokens, _ids, _amounts, _capsuleId);
    }

    function burnMultiERC1155Capsule(
        address _capsule,
        uint256 _capsuleId,
        address _burnFrom,
        address _receiver
    ) public nonReentrant sanityChecks(_capsule, _burnFrom) {
        address[] memory _tokens = _multiERC1155Capsule[_capsule][_capsuleId].tokenAddresses;
        uint256[] memory _ids = _multiERC1155Capsule[_capsule][_capsuleId].ids;
        uint256[] memory _amounts = _multiERC1155Capsule[_capsule][_capsuleId].tokenAmounts;
        // If there is no tokens in stored data then provided id is not ERC1155 Capsule id
        require(_tokens.length > 0, Errors.NOT_ERC1155_CAPSULE_ID);

        // then, delete the Capsule NFT data at id
        delete _multiERC1155Capsule[_capsule][_capsuleId];

        // burn the Capsule NFT
        ICapsule(_capsule).burn(_burnFrom, _capsuleId);

        for (uint256 i; i < _tokens.length; i++) {
            // send tokens to the _receiver
            IERC1155(_tokens[i]).safeTransferFrom(address(this), _receiver, _ids[i], _amounts[i], "");
        }

        emit MultiERC1155CapsuleBurnt(_burnFrom, _capsule, _tokens, _ids, _amounts, _capsuleId);
    }

    /******************************************************************************
     *                            Governor functions                              *
     *****************************************************************************/
    function flushTaxAmount() external {
        address _taxCollector = factory.taxCollector();
        require(_msgSender() == governor || _msgSender() == _taxCollector, Errors.UNAUTHORIZED);
        uint256 _taxAmount = address(this).balance;
        emit FlushedTaxAmount(_taxAmount);
        Address.sendValue(payable(_taxCollector), _taxAmount);
    }

    function addToWhitelist(address _user) external onlyGovernor {
        require(_user != address(0), Errors.ZERO_ADDRESS);
        require(mintWhitelist.add(_user), Errors.ADDRESS_ALREADY_EXIST);
        emit AddedToWhitelist(_user);
    }

    function removeFromWhitelist(address _user) external onlyGovernor {
        require(_user != address(0), Errors.ZERO_ADDRESS);
        require(mintWhitelist.remove(_user), Errors.ADDRESS_DOES_NOT_EXIST);
        emit RemovedFromWhitelist(_user);
    }

    /// @notice update Capsule NFT mint tax
    function updateCapsuleMintTax(uint256 _newTax) external onlyGovernor {
        require(_newTax <= MAX_CAPSULE_MINT_TAX, Errors.INCORRECT_TAX_AMOUNT);
        require(_newTax != capsuleMintTax, Errors.SAME_AS_EXISTING);
        emit CapsuleMintTaxUpdated(capsuleMintTax, _newTax);
        capsuleMintTax = _newTax;
    }

    function updateWhitelistedCallers(address _caller) external onlyGovernor {
        require(_caller != address(0), Errors.ZERO_ADDRESS);
        if (whitelistedCallers.contains(_caller)) {
            whitelistedCallers.remove(_caller);
        } else {
            whitelistedCallers.add(_caller);
        }
        emit UpdatedWhitelistedCallers(_caller);
    }

    /******************************************************************************
     *                            Internal functions                              *
     *****************************************************************************/
    function _depositToken(
        IERC20 _token,
        address _depositor,
        uint256 _amount
    ) internal returns (uint256 _actualAmount) {
        uint256 _balanceBefore = _token.balanceOf(address(this));
        _token.safeTransferFrom(_depositor, address(this), _amount);
        _actualAmount = _token.balanceOf(address(this)) - _balanceBefore;
        require(_actualAmount > 0, Errors.INVALID_TOKEN_AMOUNT);
    }

    /**
     * @dev These checks will run as first thing in each burn functions.
     * These checks will make sure that
     *  - Capsule address is valid
     *  - If caller is trying to burn other users NFT then caller should be whitelisted
     *  - Caller is collection burner meaning caller can burn NFT from this collection.
     */
    function _sanityChecks(address _capsule, address _burnFrom) internal view {
        require(factory.isCapsule(_capsule), Errors.NOT_CAPSULE);
        if (msg.sender != _burnFrom) {
            require(whitelistedCallers.contains(msg.sender), Errors.NOT_WHITELISTED_CALLERS);
        }
        require(factory.isCollectionBurner(_capsule, msg.sender), Errors.NOT_COLLECTION_BURNER);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.9;

import "./openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/ICapsuleFactory.sol";
import "./interfaces/ICapsuleMinter.sol";

abstract contract CapsuleMinterStorage is ICapsuleMinter {
    /// @notice Capsule factory address
    ICapsuleFactory public factory;

    uint256 public capsuleMintTax;

    /// @notice Mapping of a Capsule NFT address -> id -> bool, indicating if the address is a simple Capsule
    mapping(address => mapping(uint256 => bool)) public isSimpleCapsule;
    /// @notice Mapping of a Capsule NFT address -> id -> SingleERC20Capsule struct
    mapping(address => mapping(uint256 => SingleERC20Capsule)) public singleERC20Capsule;
    /// @notice Mapping of a Capsule NFT address -> id -> SingleERC721Capsule struct
    mapping(address => mapping(uint256 => SingleERC721Capsule)) public singleERC721Capsule;

    // Mapping of a Capsule NFT address -> id -> MultiERC20Capsule struct
    // It cannot be public because it contains a nested array. Instead, it has a getter function below
    mapping(address => mapping(uint256 => MultiERC20Capsule)) internal _multiERC20Capsule;

    // Mapping of a Capsule NFT address -> id -> MultiERC721Capsule struct
    // It cannot be public because it contains a nested array. Instead it has a getter function below
    mapping(address => mapping(uint256 => MultiERC721Capsule)) internal _multiERC721Capsule;

    // List of addresses which can mint Capsule NFTs without a mint tax
    EnumerableSet.AddressSet internal mintWhitelist;
}

abstract contract CapsuleMinterStorageV2 is CapsuleMinterStorage {
    // Mapping of a Capsule NFT address -> id -> MultiERC1155Capsule struct
    // It cannot be public because it contains a nested array. Instead it has a getter function below
    mapping(address => mapping(uint256 => MultiERC1155Capsule)) internal _multiERC1155Capsule;
}

abstract contract CapsuleMinterStorageV3 is CapsuleMinterStorageV2 {
    /**
     * @notice List of whitelisted callers.
     * WhitelistedCallers: Contracts which mints and burns on behalf of users
     * can be added to this list. Such contracts are part of Capsule ecosystem
     * and can be consider as extension/wrapper of CapsuleMinter contract.
     *
     * @dev WhitelistedCallers can,
     *  - Send tokens before calling mint, which enable them to send tokens
     *    from users to this contract. This eliminate 1 intermediate transfer.
     *  - Burn Capsule from given address. This eliminates approval and intermediate
     *    transfer.
     * */
    EnumerableSet.AddressSet internal whitelistedCallers;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

/// @title Errors library
library Errors {
    string public constant INVALID_TOKEN_AMOUNT = "1"; // Input token amount must be greater than 0
    string public constant INVALID_TOKEN_ADDRESS = "2"; // Input token address is zero
    string public constant INVALID_TOKEN_ARRAY_LENGTH = "3"; // Invalid tokenAddresses array length. 0 < length <= 100. Max 100 elements
    string public constant INVALID_AMOUNT_ARRAY_LENGTH = "4"; // Invalid tokenAmounts array length. 0 < length <= 100. Max 100 elements
    string public constant INVALID_IDS_ARRAY_LENGTH = "5"; // Invalid tokenIds array length. 0 < length <= 100. Max 100 elements
    string public constant LENGTH_MISMATCH = "6"; // Array length must be same
    string public constant NOT_NFT_OWNER = "7"; // Caller/Minter is not NFT owner
    string public constant NOT_CAPSULE = "8"; // Provided address or caller is not a valid Capsule address
    string public constant NOT_MINTER = "9"; // Provided address or caller is not Capsule minter
    string public constant NOT_COLLECTION_MINTER = "10"; // Provided address or caller is not collection minter
    string public constant ZERO_ADDRESS = "11"; // Input/provided address is zero.
    string public constant NON_ZERO_ADDRESS = "12"; // Address under check must be 0
    string public constant SAME_AS_EXISTING = "13"; // Provided address/value is same as stored in state
    string public constant NOT_SIMPLE_CAPSULE = "14"; // Provided Capsule id is not simple Capsule
    string public constant NOT_ERC20_CAPSULE_ID = "15"; // Provided token id is not the id of single/multi ERC20 Capsule
    string public constant NOT_ERC721_CAPSULE_ID = "16"; // Provided token id is not the id of single/multi ERC721 Capsule
    string public constant ADDRESS_DOES_NOT_EXIST = "17"; // Provided address does not exist in valid address list
    string public constant ADDRESS_ALREADY_EXIST = "18"; // Provided address does exist in valid address lists
    string public constant INCORRECT_TAX_AMOUNT = "19"; // Tax amount is incorrect
    string public constant UNAUTHORIZED = "20"; // Caller is not authorized to perform this task
    string public constant BLACKLISTED = "21"; // Caller is blacklisted and can not interact with Capsule protocol
    string public constant WHITELISTED = "22"; // Caller is whitelisted
    string public constant NOT_TOKEN_URI_OWNER = "23"; // Provided address or caller is not tokenUri owner
    string public constant NOT_ERC1155_CAPSULE_ID = "24"; // Provided token id is not the id of single/multi ERC1155 Capsule
    string public constant NOT_WHITELISTED_CALLERS = "25"; // Caller is not whitelisted
    string public constant NOT_COLLECTION_BURNER = "26"; // Caller is not collection burner
    string public constant NOT_PRIVATE_COLLECTION = "27"; // Provided address is not private Capsule collection
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../openzeppelin/contracts/proxy/utils/Initializable.sol";
import "../openzeppelin/contracts/utils/Context.sol";
import "../interfaces/IGovernable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (governor) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the governor account will be the one that deploys the contract. This
 * can later be changed with {transferGovernorship}.
 *
 */
abstract contract Governable is IGovernable, Context, Initializable {
    address public governor;
    address private proposedGovernor;

    event UpdatedGovernor(address indexed previousGovernor, address indexed proposedGovernor);

    /**
     * @dev Initializes the contract setting the deployer as the initial governor.
     */
    constructor() {
        address msgSender = _msgSender();
        governor = msgSender;
        emit UpdatedGovernor(address(0), msgSender);
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial governor.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __Governable_init() internal onlyInitializing {
        address msgSender = _msgSender();
        governor = msgSender;
        emit UpdatedGovernor(address(0), msgSender);
    }

    /**
     * @dev Throws if called by any account other than the governor.
     */
    modifier onlyGovernor() {
        require(governor == _msgSender(), "not governor");
        _;
    }

    /**
     * @dev Transfers governorship of the contract to a new account (`proposedGovernor`).
     * Can only be called by the current governor.
     */
    function transferGovernorship(address _proposedGovernor) external onlyGovernor {
        require(_proposedGovernor != address(0), "invalid proposed governor");
        proposedGovernor = _proposedGovernor;
    }

    /**
     * @dev Allows new governor to accept governorship of the contract.
     */
    function acceptGovernorship() external {
        require(proposedGovernor == _msgSender(), "not the proposed governor");
        emit UpdatedGovernor(governor, proposedGovernor);
        governor = proposedGovernor;
        proposedGovernor = address(0);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../openzeppelin/contracts/interfaces/IERC2981.sol";

interface ICapsule is IERC721, IERC2981 {
    function mint(address account, string memory _uri) external;

    function burn(address owner, uint256 tokenId) external;

    function setMetadataProvider(address _metadataAddress) external;

    // Read functions
    function baseURI() external view returns (string memory);

    function counter() external view returns (uint256);

    function exists(uint256 tokenId) external view returns (bool);

    function isCollectionPrivate() external view returns (bool);

    function isCollectionMinter(address _account) external view returns (bool);

    function maxId() external view returns (uint256);

    function royaltyRate() external view returns (uint256);

    function royaltyReceiver() external view returns (address);

    function tokenURIOwner() external view returns (address);

    // Admin functions
    function lockCollectionCount(uint256 _nftCount) external;

    function setBaseURI(string calldata baseURI_) external;

    function setTokenURI(uint256 _tokenId, string memory _newTokenURI) external;

    function updateTokenURIOwner(address _newTokenURIOwner) external;

    function updateRoyaltyConfig(address _royaltyReceiver, uint256 _royaltyRate) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IGovernable.sol";

interface ICapsuleFactory is IGovernable {
    function capsuleMinter() external view returns (address);

    function createCapsuleCollection(
        string memory _name,
        string memory _symbol,
        address _tokenURIOwner,
        bool _isCollectionPrivate
    ) external payable returns (address);

    function collectionBurner(address _capsule) external view returns (address);

    function getAllCapsuleCollections() external view returns (address[] memory);

    function getCapsuleCollectionsOf(address _owner) external view returns (address[] memory);

    function getBlacklist() external view returns (address[] memory);

    function getWhitelist() external view returns (address[] memory);

    function isBlacklisted(address _user) external view returns (bool);

    function isCapsule(address _capsule) external view returns (bool);

    function isCollectionBurner(address _capsuleCollection, address _account) external view returns (bool);

    function isWhitelisted(address _user) external view returns (bool);

    function taxCollector() external view returns (address);

    //solhint-disable-next-line func-name-mixedcase
    function VERSION() external view returns (string memory);

    // Special permission functions
    function addToWhitelist(address _user) external;

    function removeFromWhitelist(address _user) external;

    function addToBlacklist(address _user) external;

    function removeFromBlacklist(address _user) external;

    function flushTaxAmount() external;

    function setCapsuleMinter(address _newCapsuleMinter) external;

    function updateCapsuleCollectionBurner(address _capsuleCollection, address _newBurner) external;

    function updateCapsuleCollectionOwner(address _previousOwner, address _newOwner) external;

    function updateCapsuleCollectionTax(uint256 _newTax) external;

    function updateTaxCollector(address _newTaxCollector) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IGovernable.sol";
import "./ICapsuleFactory.sol";

interface ICapsuleMinter is IGovernable {
    struct SingleERC20Capsule {
        address tokenAddress;
        uint256 tokenAmount;
    }

    struct MultiERC20Capsule {
        address[] tokenAddresses;
        uint256[] tokenAmounts;
    }

    struct SingleERC721Capsule {
        address tokenAddress;
        uint256 id;
    }

    struct MultiERC721Capsule {
        address[] tokenAddresses;
        uint256[] ids;
    }

    struct MultiERC1155Capsule {
        address[] tokenAddresses;
        uint256[] ids;
        uint256[] tokenAmounts;
    }

    function factory() external view returns (ICapsuleFactory);

    function getMintWhitelist() external view returns (address[] memory);

    function getCapsuleOwner(address _capsule, uint256 _id) external view returns (address);

    function getWhitelistedCallers() external view returns (address[] memory);

    function isMintWhitelisted(address _user) external view returns (bool);

    function isWhitelistedCaller(address _caller) external view returns (bool);

    function multiERC20Capsule(address _capsule, uint256 _id) external view returns (MultiERC20Capsule memory _data);

    function multiERC721Capsule(address _capsule, uint256 _id) external view returns (MultiERC721Capsule memory _data);

    function multiERC1155Capsule(
        address _capsule,
        uint256 _id
    ) external view returns (MultiERC1155Capsule memory _data);

    function singleERC20Capsule(address _capsule, uint256 _id) external view returns (address _token, uint256 _amount);

    function mintSimpleCapsule(address _capsule, string memory _uri, address _receiver) external payable;

    function burnSimpleCapsule(address _capsule, uint256 _id, address _burnFrom) external;

    function mintSingleERC20Capsule(
        address _capsule,
        address _token,
        uint256 _amount,
        string memory _uri,
        address _receiver
    ) external payable;

    function burnSingleERC20Capsule(address _capsule, uint256 _id, address _burnFrom, address _receiver) external;

    function mintSingleERC721Capsule(
        address _capsule,
        address _token,
        uint256 _id,
        string memory _uri,
        address _receiver
    ) external payable;

    function burnSingleERC721Capsule(address _capsule, uint256 _id, address _burnFrom, address _receiver) external;

    function mintMultiERC20Capsule(
        address _capsule,
        address[] memory _tokens,
        uint256[] memory _amounts,
        string memory _uri,
        address _receiver
    ) external payable;

    function burnMultiERC20Capsule(address _capsule, uint256 _id, address _burnFrom, address _receiver) external;

    function mintMultiERC721Capsule(
        address _capsule,
        address[] memory _tokens,
        uint256[] memory _ids,
        string memory _uri,
        address _receiver
    ) external payable;

    function burnMultiERC721Capsule(address _capsule, uint256 _id, address _burnFrom, address _receiver) external;

    function mintMultiERC1155Capsule(
        address _capsule,
        address[] memory _tokens,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        string memory _uri,
        address _receiver
    ) external payable;

    function burnMultiERC1155Capsule(address _capsule, uint256 _id, address _burnFrom, address _receiver) external;

    // Special permission functions
    function addToWhitelist(address _user) external;

    function removeFromWhitelist(address _user) external;

    function flushTaxAmount() external;

    function updateCapsuleMintTax(uint256 _newTax) external;

    function updateWhitelistedCallers(address _caller) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @notice Governable interface
 */
interface IGovernable {
    function governor() external view returns (address _governor);

    function transferGovernorship(address _proposedGovernor) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !Address.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}
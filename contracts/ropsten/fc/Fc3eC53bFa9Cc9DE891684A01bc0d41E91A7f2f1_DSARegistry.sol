// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "./Interfaces.sol";
import "../node_modules/@openzeppelin/contracts/access/AccessControl.sol";
import "../node_modules/@openzeppelin/contracts/utils/Address.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/access/AccessControl.sol";
// import "@openzeppelin/contracts/utils/Address.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DSARegistry is IRegistry, AccessControl {
    using Address for address;

    address payable public SpaceChain;

    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    mapping(address => bool) public blacklist;
    mapping(address => REGISTRATION) private registry;

    REGISTRATION[] private registerArray;
    DATA[] private dataArray;
    METADATA[] public metadataArray;

    mapping(address => DATA[]) private userUploads;
    mapping(address => uint256[]) private userDownloadIds;
    mapping(address => USERDOWNLOADDATA[]) private userDownloadData;
    mapping(uint256 => USERDOWNLOADDATA) private downloadIdData;

    mapping(address => uint256) private registerIndex;

    // download id => IPFS hash
    mapping(uint256 => bytes32) private downloadDatasets;
    // dataset name => DATA
    mapping(bytes32 => DATA) private datasets;
    mapping(bytes32 => METADATA) public metadata;
    mapping(uint256 => PAYMENT) private payments;

    uint256 public cutPerMillion;
    uint256 public constant maxCutPerMillion = 100000; // 10% or 0.1 of 1 million

    uint256 registryArrayIndex;
    uint256 dataArrayIndex;

    /**
     * This function will allow contract receive ether
     */
    receive() payable external {}

    constructor(address _SpaceChain) {
        require(_SpaceChain != address(0), "cannot set zero address as spacechain wallet");
        SpaceChain = payable(_SpaceChain);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OWNER_ROLE, msg.sender);
    }

    /**
     * This function will register new general or enterprise users
     * @param accountType 0 for general and 1 for enterprise 
     * @param onBehalfOf The address to register
     */
    function register(uint8 accountType, address onBehalfOf)
        external
        override
    {
        require(!blacklist[onBehalfOf], "cannot register a blacklisted address");
        require(
            uint256(ACCOUNT_TYPE.ENTERPRISE) >= accountType,
            "register: invalid account type"
        );
        
        REGISTRATION storage r = registry[onBehalfOf];

        // if user is already registered, they can only re-register with a different account type
        // to switch accounts
        if ((r.user != address(0)) && (r.approved)) {
            require(accountType != uint256(r.acc_type), "register: address is already registered");
        } else if ((r.user == address(0)) && (!r.approved)) {
            // only create new array element for fresh accounts
            // enterprise wallets will be duplicated otherwise because their
            // approved is false but r.user is not address(0)
            // which is opposite of if case where user is not switching 
            // accounts but waiting approval and calls register again
            r.arrayIndex = registryArrayIndex++;
            registerArray.push(r);
            registerIndex[onBehalfOf] = r.arrayIndex;
        }

        // ENTERPRISE wallet is normal EOA managed by external user
        if (onBehalfOf != msg.sender) {
            require(onBehalfOf != address(0), "register: cannot register zero address");
            r.user = onBehalfOf;
        } else {
            r.user = onBehalfOf;
        }
        
        r.approved = false;

        // if user is client type, register them
        if (ACCOUNT_TYPE(accountType) == ACCOUNT_TYPE.GENERAL) {
            r.approved = true;
            r.pending = false;
        }

        if (ACCOUNT_TYPE(accountType) == ACCOUNT_TYPE.ENTERPRISE) {
            r.pending = true;
        }
        
        r.acc_type = ACCOUNT_TYPE(accountType);

        if(hasRole(OWNER_ROLE, msg.sender)) {
            r.approved = true;
            r.pending = false;
        }

        registerArray[registerIndex[onBehalfOf]] = r;        
        emit Registration(accountType, r.user);
    }

    modifier onlyOwners() {
        require(
            hasRole(OWNER_ROLE, msg.sender),
            "Caller does not have the OWNER_ROLE"
        );
        _;
    }

    /**
     * This function will make each data download unique with a unique id generated from
     * the resulting hash
     */
    function generateDatadownloadId()
        external
        view
        override
        returns (uint256)
    {
        return
            uint256(
                keccak256(
                    abi.encode(
                        msg.sender,
                        block.timestamp
                    )
                )
            );
    }

    /**
     * This function will add an address to the blacklist.
     * Preventing the address from interacting with other functions of the contract
     * @param account The address to blacklist
     * @param blocked bool true to block and false to unblock
     */
    function updateBlackList(address account, bool blocked)
        external
        override
        onlyOwners
    {
        blacklist[account] = blocked;
        REGISTRATION memory s = getAccount(account);
        // if user is registered, update account at array index
        if (s.user != address(0)) {
            registerArray[registerIndex[account]].blacklisted = blocked;
        }
        emit BlacklistUpdated(account, blocked);
    }

    /**
     * This function will create and store details related to a new data
     * download, e.g., payment information and ipfs Hash
     * Note: It will also collect payment from user using ERC-20 transferFrom() function
     * so user must have approved this smart contract for the amount to pay
     * before calling this function by calling 
     * approve(spender, amount) on the ERC-20 contract for acceptedToken above
     * Note: This function calls uploadData() function in this contract which is a public function
     * used to store the IPFS hash of the purchased dataset and callable by this contract itself or admin
     * @param downloadId The download id
     * @param datasetId unique id of dataset
     */
    function newDatadownload(
        uint256 downloadId,
        bytes32 datasetId
    ) external payable override {
        require(!blacklist[msg.sender], "cannot create download with blacklisted address");

        require(
            downloadIdData[downloadId].buyer == address(0),
            "download id already assigned"
        );

        bytes32 ipfsHash = datasets[datasetId].ipfsHash;
        uint8 dataAccess = uint8(datasets[datasetId].access);

        if (dataAccess == 0) {
            require(uint8(registry[msg.sender].acc_type) == dataAccess, "only regular user can download");
        } else if (dataAccess == 1) {
            require(uint8(registry[msg.sender].acc_type) == dataAccess, "only enterprise user can download");
        }

        downloadDatasets[downloadId] = ipfsHash;
        userDownloadIds[msg.sender].push(downloadId);

        emit downloadDatasetUpdated(downloadId);

        // client and enterprise users must be registered
        require(
            registry[msg.sender].approved, 
            "user registration not approved"
        );

        // make payment for service here
        address paymentToken = datasets[datasetId].paymentToken;
        if (paymentToken == address(0)) {
            require(msg.value == datasets[datasetId].amount, "check msg.value equals dataset price");

            uint256 saleShareAmount;
            if (cutPerMillion > 0) {
                // Calculate sale share
                saleShareAmount = (datasets[datasetId].amount * cutPerMillion) / 1e6;
            }

            uint256 enterpriseAmount = datasets[datasetId].amount - saleShareAmount;
            address enterprise = datasets[datasetId].uploader;

            downloadIdData[downloadId] = USERDOWNLOADDATA({buyer: msg.sender, enterprise: enterprise, datasetId: datasetId, symbol: ERC20(datasets[datasetId].paymentToken).symbol(), paymentToken: datasets[datasetId].paymentToken, amount: datasets[datasetId].amount, ipfsHash: ipfsHash});
            userDownloadData[msg.sender].push(USERDOWNLOADDATA({buyer: msg.sender, enterprise: enterprise, datasetId: datasetId, symbol: ERC20(datasets[datasetId].paymentToken).symbol(), paymentToken: datasets[datasetId].paymentToken, amount: datasets[datasetId].amount, ipfsHash: ipfsHash}));

            payable(enterprise).transfer(enterpriseAmount);
            
            payments[downloadId] = PAYMENT({
                symbol: ERC20(datasets[datasetId].paymentToken).symbol(),
                paymentToken: datasets[datasetId].paymentToken,
                enterpriseFee: enterpriseAmount, // amount for enterprise EOA
                adminFee: saleShareAmount, // fees to platform/SpaceChain
                adminFeeWithdrawn: false,
                enterpriseFeeWithdrawn: true
            });
            
            emit Newdownload(downloadId, ERC20(datasets[datasetId].paymentToken).symbol(), datasets[datasetId].paymentToken, datasets[datasetId].amount);  

        } else {
            IERC20(paymentToken).transferFrom(
                msg.sender,
                address(this), 
                datasets[datasetId].amount
            );

            uint256 saleShareAmount;
            if (cutPerMillion > 0) {
                // Calculate sale share
                saleShareAmount = (datasets[datasetId].amount * cutPerMillion) / 1e6;
            }

            uint256 enterpriseAmount = datasets[datasetId].amount - saleShareAmount;
            address enterprise = datasets[datasetId].uploader;

            downloadIdData[downloadId] = USERDOWNLOADDATA({buyer: msg.sender, enterprise: enterprise, datasetId: datasetId, symbol: ERC20(datasets[datasetId].paymentToken).symbol(), paymentToken: datasets[datasetId].paymentToken, amount: datasets[datasetId].amount, ipfsHash: ipfsHash});
            userDownloadData[msg.sender].push(USERDOWNLOADDATA({buyer: msg.sender, enterprise: enterprise, datasetId: datasetId, symbol: ERC20(datasets[datasetId].paymentToken).symbol(), paymentToken: datasets[datasetId].paymentToken, amount: datasets[datasetId].amount, ipfsHash: ipfsHash}));

            IERC20(paymentToken).transfer(
                enterprise, 
                enterpriseAmount
            );
            payments[downloadId] = PAYMENT({
                symbol: ERC20(datasets[datasetId].paymentToken).symbol(),
                paymentToken: datasets[datasetId].paymentToken,
                enterpriseFee: enterpriseAmount, // amount for enterprise EOA
                adminFee: saleShareAmount, // fees to platform/SpaceChain
                adminFeeWithdrawn: false,
                enterpriseFeeWithdrawn: true
            });
            
            emit Newdownload(downloadId, ERC20(datasets[datasetId].paymentToken).symbol(), datasets[datasetId].paymentToken, datasets[datasetId].amount);   
        }
    }

    /**
     * This function will store IPFS hash associated with the download Id
     * after receiving payment.
     * The function is only callable by this contract or admins
     * to update the stored ipfs hash in the case of any issues
     * or update to the dataset associated with a download id
     * @param downloadId The download id
     * @param ipfsHash IPFS hash
     */
    function updateIPFSHashFordownload (
        uint256 downloadId,
        bytes32 ipfsHash
    ) external override {
        require(
            hasRole(OWNER_ROLE, msg.sender),
            "caller must be admin"
        );
        require(ipfsHash.length != 0, "ipfs hash length is 0");
        require(ipfsHash != 0x0, "invalid ipfs hash with zero bytes");
        downloadDatasets[downloadId] = ipfsHash;
        emit downloadDatasetUpdated(downloadId);
    }

    function uploadDataset(
        address paymentToken,
        uint256 amount, 
        bytes32 datasetId, 
        bytes32 ipfsHash, 
        uint8 dataAccess
    ) external override {
        REGISTRATION storage r = registry[msg.sender];
        require(
            uint8(DATA_ACCESS.ALL) >= dataAccess,
            "invalid access type"
        );
        require(amount > 0, "cannot charge 0 for dataset");
        require(ipfsHash.length != 0, "ipfs hash length is 0");
        require(ipfsHash != 0x0, "invalid ipfs hash");
        require(datasetId.length != 0, "datasetId hash length is 0");
        require(datasetId != 0x0, "invalid dataset name");
        require(datasets[datasetId].ipfsHash == 0x0, "dataset already exists for this dataset name");

        require(
            r.approved ||
            hasRole(OWNER_ROLE, msg.sender),
            "uploadData: invalid msg.sender, caller must be enterprise or admin"
        );

        // add to array index to include in getAllDatasets()
        datasets[datasetId].arrayIndex = dataArrayIndex++;

        datasets[datasetId].paymentToken = paymentToken;
        datasets[datasetId].amount = amount;
        datasets[datasetId].ipfsHash = ipfsHash;
        datasets[datasetId].access = DATA_ACCESS(dataAccess);

        metadata[datasetId] = METADATA({symbol: ERC20(datasets[datasetId].paymentToken).symbol(), paymentToken: paymentToken, amount: amount, access: DATA_ACCESS(dataAccess)});
    
        if (hasRole(OWNER_ROLE, msg.sender)) {
            datasets[datasetId].admin = msg.sender;
        } 
        datasets[datasetId].uploader = msg.sender;
        userUploads[msg.sender].push(datasets[datasetId]);

        dataArray.push(datasets[datasetId]);
        metadataArray.push(metadata[datasetId]);

        emit NewDatasetCreated(amount, datasetId, msg.sender);
    }

    function updateDatasetAccess(
        bytes32 datasetId, 
        uint8 dataAccess
    ) external override {
        REGISTRATION storage r = registry[msg.sender];
        require(
            uint8(DATA_ACCESS.ALL) >= dataAccess,
            "invalid access type"
        );
        require(datasetId.length != 0, "datasetId hash length is 0");
        require(datasetId != 0x0, "invalid dataset name");

        require(
            datasets[datasetId].uploader == msg.sender && 
            !hasRole(OWNER_ROLE, msg.sender), 
            "only dataset uploader can modify"
        );

        require(
            r.acc_type == ACCOUNT_TYPE.ENTERPRISE,
            "invalid msg.sender, caller must be enterprise or admin"
        );

        require(
            datasets[datasetId].ipfsHash != 0x0,
            "no dataset for dataset name"
        );

        datasets[datasetId].access = DATA_ACCESS(dataAccess);
        
        emit DatasetAccessUpdated(datasetId, dataAccess);
    }

    /**
     * This function will either be used to approve or block/stop a users registration
     * It is only callable by admins to approve enterprise user type
     * @param clientOrEnterprise The address to approve or block
     * @param approve true or false
     */
    function updateUserRegistration(address clientOrEnterprise, bool approve)
        external
        override
        onlyOwners
    {
        REGISTRATION storage r = registry[clientOrEnterprise];
        if (!approve) {
            require(r.approved == true, "updateUserRegistration: user registration already deactivated");
            r.approved = approve;
            r.pending = false;
            r.approvedBy[0] = address(0);
            r.approvedBy[1] = address(0);
        } else {
            require(r.approved == false, "updateUserRegistration: user registration already approved/activated");
            if (r.acc_type == ACCOUNT_TYPE.GENERAL) {
                r.pending = false;
                r.approved = approve;
                r.approvedBy[0] = msg.sender;
            } else {
                if (r.approvedBy[0] == address(0)) {
                    r.approvedBy[0] = msg.sender;
                } else {
                    if (
                        r.approvedBy[1] == address(0) && 
                        r.approvedBy[0] != msg.sender
                    ) {
                        r.approvedBy[1] = msg.sender;
                    }
                }
                r.approved = approve;

                if (
                    r.approvedBy[1] == address(0) ||
                    r.approvedBy[0] == address(0)
                ) {
                    r.approved = false;
                    r.pending = true;
                } else if (
                    r.approvedBy[1] != address(0) &&
                    r.approvedBy[0] != address(0)
                ) {
                    r.approved = approve;
                    r.pending = false;
                }
            }
        }
        
        registerArray[registerIndex[clientOrEnterprise]] = r;

        emit UserRegistrationUpdated(clientOrEnterprise, approve);
    }

    /**
     * This function will enable users to deregister themselves.
     * It will set approve status for user to false
     * @param approve true or false. User needs to specify false to deregister.
     */
    function removeRegistration(bool approve) external override {
        REGISTRATION storage r = registry[msg.sender];

        require(
            r.approved == true,
            "removeRegistration: registration already deactivated"
        );

        if (!approve) {
            registry[msg.sender].approved = approve;
            registry[msg.sender].pending = false;
            registry[msg.sender].approvedBy[0] = address(0);
            registry[msg.sender].approvedBy[1] = address(0);
            emit UserRegistrationUpdated(msg.sender, approve);
        }
        registerArray[registerIndex[msg.sender]] = r;
    }

    /**
     * This function will set the platform share of the fees paid for
     * IPFS data in the form of the accepted token.
     * @param _cutPerMillion owners share measured out of 1 million. E.g., 100,000
     * is 10% of 1 million so for every payment, SpaceChain will get 10%
     */
    function setOwnerCutPerMillion(uint256 _cutPerMillion)
        external
        override
        onlyOwners
    {
        require(
            _cutPerMillion > 0 && _cutPerMillion <= maxCutPerMillion,
            "setOwnerCutPerMillion: the owner cut should be between 0 and maxCutPerMillion"
        );

        cutPerMillion = _cutPerMillion;
        emit ChangedFeePerMillion(cutPerMillion);
    }

    /**
    * TODO: CURRENTLY ENTERPRISE FEE IS SENT TO THEIR WALLET UPON DOWNLOAD REQUEST
     * This function is used by enterprise user to withdraw or collect
     * payment made for their dataset by general user
     * Admin can also call in case enterprise wallet misplaces their account private key
     * or do not hold ether for gas fees
     * @param downloadId The download id
     * @param to The wallet where they want the funds to go to
     */
    function withdrawEnterpriseFee(uint256 downloadId, address to)
        external
        override
    {
        USERDOWNLOADDATA memory s = downloadIdData[downloadId];
        require(
            msg.sender == s.enterprise ||
            hasRole(OWNER_ROLE, msg.sender),
            "withdrawEnterpriseFee: invalid msg.sender, caller must be enterprise or admin"
        );
        PAYMENT storage c = payments[downloadId];
        uint256 amount = c.enterpriseFee;
        c.enterpriseFee = 0;
        if (!c.enterpriseFeeWithdrawn && amount > 0) {
            if (c.paymentToken == address(0)) {
                if (to == address(0)) {
                    payable(msg.sender).transfer(amount);
                    emit PaymentWithdrawn(ERC20(c.paymentToken).symbol(), c.paymentToken, amount, downloadId, msg.sender);
                } else {
                    payable(to).transfer(amount);
                    emit PaymentWithdrawn(ERC20(c.paymentToken).symbol(), c.paymentToken, amount, downloadId, to);
                }
                c.enterpriseFeeWithdrawn = true;
            } else {
                if (to == address(0)) {
                    IERC20(c.paymentToken).transfer(msg.sender, amount);
                    emit PaymentWithdrawn(ERC20(c.paymentToken).symbol(), c.paymentToken, amount, downloadId, msg.sender);
                } else {
                    IERC20(c.paymentToken).transfer(to, amount);
                    emit PaymentWithdrawn(ERC20(c.paymentToken).symbol(), c.paymentToken, amount, downloadId, to);
                }
                c.enterpriseFeeWithdrawn = true;
            }
        }
    }

    /**
     * This function is used by admins to withdraw or collect
     * percentage of payment made for dataset by general user
     * as fees for the platform. The funds are sent to SpaceChain wallet address
     * above. This address is only changeable by admins using the 
     * setSpaceChainWallet() function
     * @param downloadId The download id
     */
    function withdrawAdminFee(uint256 downloadId)
        external
        override
    {
        PAYMENT storage c = payments[downloadId];
        uint256 amount = c.adminFee;
        c.adminFee = 0;
        require(SpaceChain != address(0), "spacechain address not set");
        if (!c.adminFeeWithdrawn && amount > 0) {
            if (c.paymentToken == address(0)) {
                payable(SpaceChain).transfer(amount);
                emit FeeWithdrawn(ERC20(c.paymentToken).symbol(), c.paymentToken, amount, SpaceChain);
                c.adminFeeWithdrawn = true;
            } else {
                IERC20(c.paymentToken).transfer(SpaceChain, amount);
                emit FeeWithdrawn(ERC20(c.paymentToken).symbol(), c.paymentToken, amount, SpaceChain);
                c.adminFeeWithdrawn = true;
            }
            
        }
    }

    /**
     * This function is used by admins to update the
     * SpaceChain wallet used in collecting platform fees 
     * @param _spacechain The new SpaceChain wallet address
     */
    function setSpaceChainWallet(address _spacechain) external override onlyOwners {
        require(_spacechain != address(0), "setSpaceChainWallet: cannot set zero address");
        SpaceChain = payable(_spacechain);
    }

    function getAccount(address account)
        public
        view
        override
        returns (REGISTRATION memory)
    {
        return registry[account];
    }

    function getAllAccounts()
        external
        view
        override
        onlyOwners
        returns (REGISTRATION[] memory)
    {
        return registerArray;
    }

    function getAllDatasets()
        external
        view
        override
        onlyOwners
        returns (DATA[] memory)
    {
        return dataArray;
    }

    function getdownloadDataHash(uint256 downloadId)
        external
        view
        override
        returns (bytes32 ipfsHash)
    {
        USERDOWNLOADDATA memory sr = downloadIdData[downloadId];
        require(
            msg.sender == sr.buyer ||
            hasRole(OWNER_ROLE, msg.sender),
            "only client or admin can access ipfs hash"
        );

        return downloadDatasets[downloadId];
        // return downloadIdData[downloadId];
        
    }

    function getdownloadData(uint256 downloadId)
        external
        view
        override
        returns (USERDOWNLOADDATA memory)
    {
        USERDOWNLOADDATA memory sr = downloadIdData[downloadId];
        require(
            msg.sender == sr.buyer ||
            hasRole(OWNER_ROLE, msg.sender),
            "only client or admin can access ipfs hash"
        );

        return downloadIdData[downloadId];
        
    }

    function getData(bytes32 datasetId)
        external
        view
        override
        returns (bytes32 ipfsHash)
    {
        require(
            msg.sender == datasets[datasetId].uploader ||
            hasRole(OWNER_ROLE, msg.sender),
            "only client or admin can access ipfs hash"
        );

        return datasets[datasetId].ipfsHash;
    }

    function getMetaData(bytes32 datasetId) external view override returns (METADATA memory) {
        return metadata[datasetId];
    }

    function getDataPrice(bytes32 datasetId) 
    external
    view 
    override
    returns (uint256 price) 
    {
        return datasets[datasetId].amount;
    }

    function getPayment(uint256 downloadId)
        public
        view
        override
        returns (PAYMENT memory)
    {
        USERDOWNLOADDATA memory sr = downloadIdData[downloadId];
        require(
            msg.sender == sr.buyer ||
            hasRole(OWNER_ROLE, msg.sender),
            "only client or admin can access ipfs hash"
        );

        return payments[downloadId];
    }

    function getUserUploads(address account) external view override returns (DATA[] memory) {
        require(
            msg.sender == account ||
            hasRole(OWNER_ROLE, msg.sender),
            "only client or admin can access ipfs hash"
        );
        return userUploads[account];
    }   

    function getUserDownloadIds(address account) external view override returns (uint256[] memory) {
        require(
            msg.sender == account ||
            hasRole(OWNER_ROLE, msg.sender),
            "only client or admin can access ipfs hash"
        );
        return userDownloadIds[account];
    } 

    function getUserDownloadData(address account) external view override returns (USERDOWNLOADDATA[] memory) {
        require(
            msg.sender == account ||
            hasRole(OWNER_ROLE, msg.sender),
            "only client or admin can access ipfs hash"
        );
        return userDownloadData[account];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

interface IRegistry {
    /// EVENTS
    event ChangedFeePerMillion(uint256 share);
    event Registration(uint256 accountType, address account);
    event Newdownload(uint256 downloadId, string symbol, address paymentToken, uint256 amount);
    event PaymentWithdrawn(string symbol, address paymentToken, uint256 amount, uint256 indexed downloadId, address indexed account);
    event FeeWithdrawn(string symbol, address paymentToken, uint256 amount, address indexed account);
    event UserRegistrationUpdated(address indexed account, bool approve);
    event BlacklistUpdated(address indexed account, bool blocked);
    event NewDatasetCreated(uint256 amount, bytes32 datasetId, address uploader);
    event downloadDatasetUpdated(uint256 downloadId);
    event DatasetAccessUpdated(bytes32 datasetId, uint8 dataAccess);

    /// DATA
    enum ACCOUNT_TYPE {
        GENERAL,
        ENTERPRISE
    }

    /// DATA ACCESS
    enum DATA_ACCESS {
        GENERAL,
        ENTERPRISE,
        ALL
    }

    struct REGISTRATION {
        address user;
        ACCOUNT_TYPE acc_type;
        bool approved;
        address[2] approvedBy;
        bool pending;
        uint256 arrayIndex;
        bool blacklisted;
    }

    struct USERDOWNLOADDATA {
        address buyer;
        address enterprise;
        bytes32 datasetId;
        string symbol;
        address paymentToken;
        uint256 amount;
        bytes32 ipfsHash;
    }

    struct DATA {
        string symbol;
        address paymentToken;
        uint256 amount;
        bytes32 ipfsHash;
        address uploader;
        address admin;
        uint256 arrayIndex;
        DATA_ACCESS access; // specify user type that can access dataset - 0 for regular, 1 for enterprise, 2 for all
    }

    struct METADATA {
        string symbol;
        address paymentToken;
        uint256 amount;
        DATA_ACCESS access; // specify user type that can access dataset - 0 for regular, 1 for enterprise, 2 for all
    }

    struct PAYMENT {
        string symbol;
        address paymentToken;
        uint256 enterpriseFee;
        uint256 adminFee;
        bool adminFeeWithdrawn;
        bool enterpriseFeeWithdrawn;
    }

    /// FUNCTIONS



    // setters
    function register(uint8 accountType, address onBehalfOf) external;
    function generateDatadownloadId() external returns (uint256);
    function newDatadownload(
        uint256 downloadId,
        bytes32 datasetId
    ) external payable;
    function updateIPFSHashFordownload (
        uint256 downloadId,
        bytes32 ipfsHash
    ) external;
    function updateDatasetAccess(
        bytes32 datasetId, 
        uint8 dataAccess
    ) external;
    function uploadDataset(address paymentToken, uint256 amount, bytes32 datasetId, bytes32 ipfsHash, uint8 dataAccess) external;
    function updateUserRegistration(address clientOrEnterprise, bool approve) external;
    function setOwnerCutPerMillion(uint256 _cutPerMillion) external;
    function withdrawEnterpriseFee(uint256 downloadId, address to) external;
    function withdrawAdminFee(uint256 downloadId) external;
    function removeRegistration(bool approve) external;
    function updateBlackList(address account, bool blocked) external;
    function setSpaceChainWallet(address _spacechain) external;
    
    
    // getters
    
    function getAccount(address account) external returns (REGISTRATION memory);
    function getAllAccounts() external view returns (REGISTRATION[] memory);
    function getAllDatasets() external view returns (DATA[] memory);
    function getPayment(uint256 downloadId) external view returns (PAYMENT memory);
    function getData(bytes32 datasetId) external view returns (bytes32 ipfsHash);
    function getDataPrice(bytes32 datasetId) external view returns (uint256 price);
    function getdownloadDataHash(uint256 downloadId) external view returns (bytes32 ipfsHash);
    function getdownloadData(uint256 downloadId) external view returns (USERDOWNLOADDATA memory);
    function getUserUploads(address account) external view returns (DATA[] memory);
    function getUserDownloadData(address account) external view returns (USERDOWNLOADDATA[] memory);
    function getUserDownloadIds(address account) external view returns (uint256[] memory);
    function getMetaData(bytes32 datasetId) external view returns (METADATA memory);

}
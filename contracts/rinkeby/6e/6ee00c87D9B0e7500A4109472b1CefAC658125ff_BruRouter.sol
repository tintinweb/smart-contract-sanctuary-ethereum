//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

import "./interfaces/IBruFactory.sol";
import "./interfaces/IBruRouter.sol";
import "./interfaces/IBruPool.sol";

contract BruRouter is IBruRouter {
    address private factoryAddress;

    constructor(address _address) {
        factoryAddress = _address;
    }

    function deposit(
        string memory poolName,
        address tokenAddress,
        uint256 tokenAmount
    ) external override {
        address poolAddress = getPoolAddress(poolName);
        require(poolAddress != address(0), "Pool does not exist");
        IBruPool(poolAddress).deposit(msg.sender, tokenAddress, tokenAmount);
    }

    function withdraw(
        string memory poolName,
        address tokenAddress,
        uint256 tokenAmount
    ) external override {
        address poolAddress = getPoolAddress(poolName);
        require(poolAddress != address(0), "Pool does not exist");
        IBruPool(poolAddress).withdraw(msg.sender, tokenAddress, tokenAmount);
    }

    function getPoolAddress(string memory poolName)
        public
        view
        override
        returns (address)
    {
        return IBruFactory(factoryAddress).poolAddresses(poolName);
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

interface IBruPool {
    //events
    event AmountChange(
        int8 _type,
        address indexed userAddress,
        address indexed tokenAddress,
        uint256 indexed timestamp,
        uint256 tokenAmount
    );
    //public variables
    function name() external returns (string memory);

    function BORROWING_LIMIT_PERCENTAGE() external returns (uint256);

    function initialize(address adminAddress, string memory poolName) external;

    //Admin functionalties
    function allowTokens(address tokenAddress) external;

    function changeStableInterestRate(uint256 _interestRate) external;

    function changeVariableInterestRate(uint256 _interestRate) external;

    function changeBorrowingLimit(uint256 percent) external;

    function enableBorrowing() external;

    function disableBorrowing() external;

    function enableTransferOfBTokens() external;

    function disableTransferOfBTokens() external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    //Minting functionlaities
    function mintNft(
        address userAddress,
        string memory nftId,
        uint256 nftValue,
        string memory nftData
    ) external;

    // Borrow functions

    // lending functions
    function deposit(
        address userAddress,
        address tokenAddress,
        uint256 tokenAmount
    ) external;

    function withdraw(
        address userAddress,
        address tokenAddress,
        uint256 tokenAmount
    ) external;

    //Lending admin external functions
    function addEndOfDayBalance(address tokenAddress) external;

    function depositInterest(address tokenAddress) external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

interface IBruRouter {
    function deposit(
        string memory poolName,
        address tokenAddress,
        uint256 tokenAmount
    ) external;

    function withdraw(
        string memory poolName,
        address tokenAddress,
        uint256 tokenAmount
    ) external;
    

    function getPoolAddress(string memory name) external returns (address);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

interface IBruFactory {
    event PoolDeployed(string poolName, address poolAddress);

    function poolAddresses(string memory poolName)
        external
        view
        returns (address poolAddress);

    function deployPool(string memory poolName) external;
}
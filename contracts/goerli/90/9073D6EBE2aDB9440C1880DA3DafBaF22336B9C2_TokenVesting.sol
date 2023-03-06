// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}

interface ICallProxy {
    function anyCall(
        address _to,
        bytes calldata _data,
        uint256 _toChainID,
        uint256 _flags,
        bytes calldata _extdata
    ) external payable;
}

interface ICalcSrcFees {
    function calcSrcFees(
        address _app,
        uint256 _toChainID,
        uint256 _dataLength
    ) external view returns (uint256);
}

contract TokenVesting {
    IERC20 public token;
    uint256 public vestingStart;
    uint256 public vestingDuration;
    uint256 public totalTokens;
    mapping(address => uint256) public vestedTokens;
    mapping(uint256 => address) public interactionTarget;
    address[] public eligibleUsers;
    ICallProxy public anycallProxyContract;
    ICalcSrcFees public anycallFeeContract;

    event TokensClaimed(address indexed user, uint256 amount);

    constructor(
        IERC20 _token,
        uint256 _vestingStart,
        uint256 _vestingDuration,
        address[] memory _eligibleUsers,
        uint256[] memory _chainID,
        address[] memory _interactionAddress,
        uint256 _totalTokens,
        ICallProxy _anycallProxyContract,
        ICalcSrcFees _anycallFeeContract
    ) {
        require(
            _vestingStart >= block.timestamp,
            "Vesting start time must be in the future"
        );
        require(
            _vestingDuration > 0,
            "Vesting duration must be greater than 0"
        );
        require(_totalTokens > 0, "Total tokens must be greater than 0");
        require(
            _chainID.length == _interactionAddress.length,
            "Array lengths must be equal"
        );

        for (uint256 i = 0; i < _chainID.length; i++) {
            interactionTarget[_chainID[i]] = _interactionAddress[i];
        }

        token = _token;
        vestingStart = _vestingStart;
        vestingDuration = _vestingDuration;
        totalTokens = _totalTokens;
        anycallProxyContract = _anycallProxyContract;
        anycallFeeContract = _anycallFeeContract;

        uint256 tokensPerUser = totalTokens / _eligibleUsers.length;

        for (uint256 i = 0; i < _eligibleUsers.length; i++) {
            eligibleUsers.push(_eligibleUsers[i]);
            vestedTokens[_eligibleUsers[i]] = tokensPerUser;
        }
    }

    /**
     * @notice Transfers available for claim vested tokens to the user.
     * @param chainId The target chain id to interact with
     */
    function claimTokens(uint256 chainId) external payable {
        require(
            vestedTokens[msg.sender] > 0,
            "You have already claimed all your vested tokens"
        );

        uint256 availableTokens = getAvailableTokens(msg.sender);

        if (chainId == block.chainid) {
            vestedTokens[msg.sender] -= availableTokens;
            token.transfer(msg.sender, availableTokens);
        } else {
            require(
                interactionTarget[chainId] != address(0),
                "The cross chain interaction target not specified"
            );
            vestedTokens[msg.sender] -= availableTokens;
            bytes memory data = abi.encode(msg.sender, availableTokens);
            uint256 fee = anycallFeeContract.calcSrcFees(
                address(0),
                chainId,
                data.length
            );
            require(msg.value >= fee, "The value sent can`t cover the gas fee");
            uint256 change = msg.value - fee;
            if (change > 0) {
                (bool success, ) = msg.sender.call{value: change}("");
                require(success, "Transaction failed");
            }
            anycallProxyContract.anyCall{value: fee}(
                interactionTarget[chainId],
                data,
                chainId,
                0,
                ""
            );
        }
        emit TokensClaimed(msg.sender, availableTokens);
    }

    /**
     * @notice Calculates the amount that has already vested but hasn't been claimed yet.
     * @param account Address of the user who purchased tokens
     * @return The amount of the token vested and unclaimed.
     */
    function getAvailableTokens(address account) public view returns (uint256) {
        if (block.timestamp < vestingStart) {
            return 0;
        } else if (block.timestamp >= vestingStart + vestingDuration) {
            return vestedTokens[account];
        } else {
            uint256 tokensPerUserPerSecond = totalTokens /
                vestingDuration /
                eligibleUsers.length;
            uint256 elapsedTime = block.timestamp - vestingStart;
            uint256 vestedAmount = tokensPerUserPerSecond * elapsedTime;
            return
                vestedAmount > vestedTokens[account]
                    ? vestedTokens[account]
                    : vestedAmount;
        }
    }
}
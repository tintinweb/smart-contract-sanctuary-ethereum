// ------------------------------------------------------------------------
// MorpherBridge
// Handles deposit to and withdraws from the side chain, writing of the merkle
// root to the main chain by the side chain operator, and enforces a rolling 24 hours
// token withdraw limit from side chain to main chain.
// If side chain operator doesn't write a merkle root hash to main chain for more than
// 72 hours positions and balaces from side chain can be transferred to main chain.
// ------------------------------------------------------------------------
//SPDX-License-Identifier: GPLv3
pragma solidity 0.8.11;

import "./MorpherState.sol";
import "./MorpherUserBlocking.sol";
import "./MorpherAccessControl.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "./MorpherTradeEngine.sol";

import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@uniswap/v3-periphery/contracts/interfaces/external/IWETH9.sol';
import '@uniswap/v3-periphery/contracts/interfaces/IPeripheryImmutableState.sol';

contract MorpherBridge is Initializable, ContextUpgradeable {

    using ECDSAUpgradeable for bytes32;


    MorpherState state;
    MorpherBridge previousBridge;

    uint256 public withdrawalLimitPerUserDaily; //200k MPH per day
    uint256 public withdrawalLimitPerUserMonthly; //1M MPH per month
    uint256 public withdrawalLimitPerUserYearly; //5M MPH per year

    uint256 public withdrawalLimitGlobalDaily; 
    uint256 public withdrawalLimitGlobalMonthly;
    uint256 public withdrawalLimitGlobalYearly;
    
    mapping(address => mapping(uint256 => uint256)) public withdrawalPerUserPerDay; //[address][day] = withdrawalAmount
    mapping(address => mapping(uint256 => uint256)) public withdrawalPerUserPerMonth; //[address][month] = withdrawalAmount
    mapping(address => mapping(uint256 => uint256)) public withdrawalPerUserPerYear; //[address][year] = withdrawalAmount

    mapping(uint256 => uint256) public withdrawalsGlobalDaily;
    mapping(uint256 => uint256) public withdrawalsGlobalMonthly;
    mapping(uint256 => uint256) public withdrawalsGlobalYearly;

    bytes32 public constant ADMINISTRATOR_ROLE = keccak256("ADMINISTRATOR_ROLE");
    bytes32 public constant SIDECHAINOPERATOR_ROLE = keccak256("SIDECHAINOPERATOR_ROLE");

    struct WithdrawalDataStruct {
        bytes32 merkleRoot;
        uint256 lastUpdatedAt;
    }

    WithdrawalDataStruct public withdrawalData;

    uint256 public inactivityPeriod;
    bool public recoveryEnabled;
    mapping(bytes32 => bool) public claimFromInactivity;

    ISwapRouter public swapRouter;

    // For this example, we will set the pool fee to 0.3%.
    uint24 public constant poolFee = 3000;


    struct TokensTransferredStruct {
        uint256 amount;
        uint256 lastTransferAt;
    }
    mapping(address => mapping(uint => TokensTransferredStruct)) public tokenSentToLinkedChain;
    mapping(address => TokensTransferredStruct) public tokenClaimedOnThisChain;

    uint256 public bridgeNonce;

    event TransferToLinkedChain(
        address indexed from,
        uint256 tokens,
        uint256 totalTokenSent,
        uint256 timeStamp,
        uint256 transferNonce,
        uint256 targetChainId,
        bytes32 indexed transferHash
    );
    event TransferToLinkedChainAndWithdrawTo(
        address indexed from,
        uint256 tokens,
        uint256 totalTokenSent,
        uint256 timeStamp,
        uint256 transferNonce,
        uint256 targetChainId,
        address destinationAddress,
        bytes userSigature,
        bytes32 indexed transferHash
    );
    event TrustlessWithdrawFromSideChain(address indexed from, uint256 tokens);
    event OperatorChainTransfer(address indexed from, uint256 tokens, bytes32 sidechainTransactionHash);
    event ClaimFailedTransferToSidechain(address indexed from, uint256 tokens);
    event PositionRecoveryFromSideChain(address indexed from, bytes32 positionHash);
    event TokenRecoveryFromSideChain(address indexed from, bytes32 positionHash);
    event SideChainMerkleRootUpdated(bytes32 _rootHash);
    event WithdrawLimitReset();
    event WithdrawLimitChanged(uint256 _withdrawLimit);
    event WithdrawLimitDailyPerUserChanged(uint256 _oldLimit, uint256 _newLimit);
    event WithdrawLimitMonthlyPerUserChanged(uint256 _oldLimit, uint256 _newLimit);
    event WithdrawLimitYearlyPerUserChanged(uint256 _oldLimit, uint256 _newLimit);
    event WithdrawLimitDailyGlobalChanged(uint256 _oldLimit, uint256 _newLimit);
    event WithdrawLimitMonthlyGlobalChanged(uint256 _oldLimit, uint256 _newLimit);
    event WithdrawLimitYearlyGlobalChanged(uint256 _oldLimit, uint256 _newLimit);
    event LinkState(address _address);


    /**
     * emitted when the withdrawal was a success.
     * @param _destination: the address that received the amount
     * @param _amount: the amount of tokens
     * @param _convertedToGasToken: if it was converted to ETH/MATIC native (=true) or sent as ERC20 token (=false)
     */
    event WithdrawalSuccess(address _destination, uint _amount, bool _convertedToGasToken);

    function initialize(address _stateAddress, bool _recoveryEnabled, ISwapRouter _swapRouter) public initializer {
        state = MorpherState(_stateAddress);
        recoveryEnabled = _recoveryEnabled;
        withdrawalLimitPerUserDaily = 200000 * (10**18); //200k MPH per day
        withdrawalLimitPerUserMonthly = 1000000 * (10 ** 18); //1M MPH per month
        withdrawalLimitPerUserYearly = 5000000 * (10 ** 18); //5M MPH per year

        //TODO: Adjust limits globally
        withdrawalLimitGlobalDaily = 200000 * (10**18); //200k MPH per day
        withdrawalLimitGlobalMonthly = 1000000 * (10 ** 18); //1M MPH per month
        withdrawalLimitGlobalYearly = 5000000 * (10 ** 18); //5M MPH per year
        inactivityPeriod = 3 days;
        swapRouter = _swapRouter;
    }

    modifier sideChainInactive {
        require(block.timestamp - inactivityPeriod > withdrawalData.lastUpdatedAt, "MorpherBridge: Function can only be called if sidechain is inactive.");
        _;
    }

    modifier onlyRecoveryEnabled() {
        require(recoveryEnabled, "MorpherBridge: Recovery functions are not enabled");
        _;
    }

    modifier userNotBlocked {
        require(!MorpherUserBlocking(state.morpherUserBlockingAddress()).userIsBlocked(_msgSender()), "MorpherBridge: User is blocked");
        _;
    }

    modifier onlyRole(bytes32 role) {
        require(MorpherAccessControl(state.morpherAccessControlAddress()).hasRole(role, _msgSender()), "MorpherBridge: Permission denied.");
        _;
    }
    
    // ------------------------------------------------------------------------
    // Links Token Contract with State
    // ------------------------------------------------------------------------
    function setMorpherState(address _stateAddress) public onlyRole(ADMINISTRATOR_ROLE) {
        state = MorpherState(_stateAddress);
        emit LinkState(_stateAddress);
    }

    function updateSwapRouter(ISwapRouter _swapRouter) public onlyRole(ADMINISTRATOR_ROLE) {
        swapRouter = _swapRouter;
    }


    function setInactivityPeriod(uint256 _periodInSeconds) public onlyRole(ADMINISTRATOR_ROLE) {
        inactivityPeriod = _periodInSeconds;
    }

    function updateSideChainMerkleRoot(bytes32 _rootHash) public onlyRole(SIDECHAINOPERATOR_ROLE) {
        withdrawalData.merkleRoot = _rootHash;
        withdrawalData.lastUpdatedAt = block.timestamp;
        emit SideChainMerkleRootUpdated(_rootHash);
    }

    function updateWithdrawLimitPerUserDaily(uint256 _withdrawLimit) public onlyRole(SIDECHAINOPERATOR_ROLE) {
        emit WithdrawLimitDailyPerUserChanged(withdrawalLimitPerUserDaily, _withdrawLimit);
        withdrawalLimitPerUserDaily = _withdrawLimit;
    }

    function updateWithdrawLimitPerUserMonthly(uint256 _withdrawLimit) public onlyRole(SIDECHAINOPERATOR_ROLE) {
        emit WithdrawLimitMonthlyPerUserChanged(withdrawalLimitPerUserMonthly, _withdrawLimit);
        withdrawalLimitPerUserMonthly = _withdrawLimit;
    }
    function updateWithdrawLimitPerUserYearly(uint256 _withdrawLimit) public onlyRole(SIDECHAINOPERATOR_ROLE) {
        emit WithdrawLimitYearlyPerUserChanged(withdrawalLimitPerUserYearly, _withdrawLimit);
        withdrawalLimitPerUserYearly = _withdrawLimit;
    }

    function updateWithdrawLimitGlobalDaily(uint256 _withdrawLimit) public onlyRole(SIDECHAINOPERATOR_ROLE) {
        emit WithdrawLimitDailyGlobalChanged(withdrawalLimitGlobalDaily, _withdrawLimit);
        withdrawalLimitGlobalDaily = _withdrawLimit;
    }

    function updateWithdrawLimitGlobalMonthly(uint256 _withdrawLimit) public onlyRole(SIDECHAINOPERATOR_ROLE) {
        emit WithdrawLimitMonthlyGlobalChanged(withdrawalLimitGlobalMonthly, _withdrawLimit);
        withdrawalLimitGlobalMonthly = _withdrawLimit;
    }
    function updateWithdrawLimitGlobalYearly(uint256 _withdrawLimit) public onlyRole(SIDECHAINOPERATOR_ROLE) {
        emit WithdrawLimitYearlyGlobalChanged(withdrawalLimitGlobalYearly, _withdrawLimit);
        withdrawalLimitGlobalYearly = _withdrawLimit;
    }


    function isNotDailyLimitExceeding(address _usr, uint256 _amount) public view returns(bool) {
        return (
            (withdrawalPerUserPerDay[_usr][block.timestamp / 1 days] + _amount <= withdrawalLimitPerUserDaily) && 
            (withdrawalsGlobalDaily[block.timestamp / 1 days] + _amount <= withdrawalLimitGlobalDaily)
        );
    }
    function isNotMonthlyLimitExceeding(address _usr, uint256 _amount) public view returns(bool) {
        return (
            (withdrawalPerUserPerMonth[_usr][block.timestamp / 30 days] + _amount <= withdrawalLimitPerUserMonthly) &&
            (withdrawalsGlobalMonthly[block.timestamp / 30 days] + _amount <= withdrawalLimitGlobalMonthly)
        );
    }
    function isNotYearlyLimitExceeding(address _usr, uint256 _amount) public view returns(bool) {
        return (
            (withdrawalPerUserPerYear[_usr][block.timestamp / 365 days] + _amount <= withdrawalLimitPerUserYearly) &&
            (withdrawalsGlobalYearly[block.timestamp / 365 days] + _amount <= withdrawalLimitGlobalYearly)
        );
    }

    function verifyUpdateDailyLimit(address _usr, uint256 _amount) public {
        require(isNotDailyLimitExceeding(_usr, _amount), "MorpherBridge: Withdrawal Amount exceeds daily limit");
        withdrawalPerUserPerDay[_usr][block.timestamp / 1 days] += _amount;
        withdrawalsGlobalDaily[block.timestamp / 1 days] += _amount;
    }

    function verifyUpdateMonthlyLimit(address _usr, uint256 _amount) public {
        require(isNotMonthlyLimitExceeding(_usr, _amount), "MorpherBridge: Withdrawal Amount exceeds monthly limit");
        withdrawalPerUserPerMonth[_usr][block.timestamp / 30 days] += _amount;
        withdrawalsGlobalMonthly[block.timestamp / 30 days] += _amount;
    }

    function verifyUpdateYearlyLimit(address _usr, uint256 _amount) public {
        require(isNotYearlyLimitExceeding(_usr, _amount), "MorpherBridge: Withdrawal Amount exceeds yearly limit");
        withdrawalPerUserPerYear[_usr][block.timestamp / 365 days] += _amount;
        withdrawalsGlobalYearly[block.timestamp / 365 days] += _amount;
    }

    
    /**
    * stageTokensForTransfer [chain A] => claimTokens [chain B]
    *     former: transferToSideChain(uint256 _tokens)
    * 
    * Tokens are burned on chain A and then, after the merkle root is written, 
    * can be credited on chain B through claimStagedTokens(...) below
    *
    */
    function stageTokensForTransfer(uint256 _tokens, uint _targetChainId) public userNotBlocked {
        
        verifyUpdateDailyLimit(_msgSender(), _tokens);
        verifyUpdateMonthlyLimit(_msgSender(), _tokens);
        verifyUpdateYearlyLimit(_msgSender(), _tokens);
        uint withdrawalCost = 100 ether;
        
        MorpherToken(state.morpherTokenAddress()).burn(_msgSender(), withdrawalCost); //BURN 100 MPH as a Withdrawal Fee

        uint tokensToWithdraw = _tokens - withdrawalCost;
        MorpherToken(state.morpherTokenAddress()).burn(_msgSender(), tokensToWithdraw);


        uint256 _newTokenSentToLinkedChain = tokenSentToLinkedChain[_msgSender()][_targetChainId].amount + tokensToWithdraw;
        uint256 _transferNonce = getAndIncreaseBridgeNonce();
        uint256 _timeStamp = block.timestamp;
        bytes32 _transferHash = keccak256(
            abi.encodePacked(
                _msgSender(),
                tokensToWithdraw,
                _newTokenSentToLinkedChain,
                _timeStamp,
                _targetChainId,
                _transferNonce
            )
        );
        tokenSentToLinkedChain[_msgSender()][_targetChainId].amount =  _newTokenSentToLinkedChain;
        tokenSentToLinkedChain[_msgSender()][_targetChainId].lastTransferAt = block.timestamp;
        emit TransferToLinkedChain(_msgSender(), tokensToWithdraw, _newTokenSentToLinkedChain, _timeStamp, _transferNonce, _targetChainId, _transferHash);
    }
    
    /**
    * stageTokensForTransfer [chain A] => claimTokens [chain B]
    *     former: transferToSideChain(uint256 _tokens)
    * 
    * Tokens are burned on chain A and then, after the merkle root is written, 
    * can be credited on chain B through claimStagedTokens(...) below
    *
    */
    function stageTokensForTransfer(uint256 _tokens, uint _targetChainId, address _autoWithdrawalAddressTo, bytes memory _signature) public userNotBlocked {
        verifyUpdateDailyLimit(_msgSender(), _tokens);
        verifyUpdateMonthlyLimit(_msgSender(), _tokens);
        verifyUpdateYearlyLimit(_msgSender(), _tokens);
        
        uint withdrawalCost = 100 ether;
        
        MorpherToken(state.morpherTokenAddress()).burn(_msgSender(), withdrawalCost); //BURN 100 MPH as a Withdrawal Fee

        uint tokensToWithdraw = _tokens - withdrawalCost;
        MorpherToken(state.morpherTokenAddress()).burn(_msgSender(), tokensToWithdraw);
        uint256 _newTokenSentToLinkedChain = tokenSentToLinkedChain[_msgSender()][_targetChainId].amount + tokensToWithdraw;
        uint256 _transferNonce = getAndIncreaseBridgeNonce();
        uint256 _timeStamp = block.timestamp;
        bytes32 _transferHash = keccak256(
            abi.encodePacked(
                _msgSender(),
                tokensToWithdraw,
                _newTokenSentToLinkedChain,
                _timeStamp,
                _targetChainId,
                _transferNonce
            )
        );
        tokenSentToLinkedChain[_msgSender()][_targetChainId].amount =  _newTokenSentToLinkedChain;
        tokenSentToLinkedChain[_msgSender()][_targetChainId].lastTransferAt = block.timestamp;
        emit TransferToLinkedChainAndWithdrawTo(_msgSender(), tokensToWithdraw, _newTokenSentToLinkedChain, _timeStamp, _transferNonce, _targetChainId, _autoWithdrawalAddressTo, _signature, _transferHash);
    }
    
    // ------------------------------------------------------------------------
    // claimStagedTokens(...) former: trustlessTransferFromSideChain(uint256 _numOfToken, uint256 _claimLimit, bytes32[] memory _proof)
    // Performs a merkle proof on the number of token that have been burned by the user on the side chain.
    // If the number of token claimed on the main chain is less than the number of burned token on the side chain
    // the difference (or less) can be claimed on the main chain.
    // ------------------------------------------------------------------------
    function claimStagedTokens(uint256 _numOfToken, uint256 _claimLimit, bytes32[] memory _proof) public userNotBlocked {
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender(), _claimLimit, block.chainid));
        uint256 _tokenClaimed = tokenClaimedOnThisChain[_msgSender()].amount;  
        require(mProof(_proof, leaf), "MorpherBridge: Merkle Proof failed. Please make sure you entered the correct claim limit.");
        require(_tokenClaimed + _numOfToken <= _claimLimit, "MorpherBridge: Token amount exceeds token deleted on linked chain."); 

        verifyUpdateDailyLimit(_msgSender(), _numOfToken);
        verifyUpdateMonthlyLimit(_msgSender(), _numOfToken);
        verifyUpdateYearlyLimit(_msgSender(), _numOfToken);        

        _chainTransfer(_msgSender(), _tokenClaimed, _numOfToken);   
        emit TrustlessWithdrawFromSideChain(_msgSender(), _numOfToken);
    }
    
    // ------------------------------------------------------------------------
    // claimStagedTokens(...) former: trustlessTransferFromSideChain(uint256 _numOfToken, uint256 _claimLimit, bytes32[] memory _proof)
    // Performs a merkle proof on the number of token that have been burned by the user on the side chain.
    // If the number of token claimed on the main chain is less than the number of burned token on the side chain
    // the difference (or less) can be claimed on the main chain.
    // ------------------------------------------------------------------------
    function claimStagedTokensConvertAndSend(uint256 _numOfToken, uint256 _claimLimit, bytes32[] memory _proof, address payable _finalOutput) public userNotBlocked {
        // msg.sender must approve this contract
        
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender(), _claimLimit, block.chainid));
        uint256 _tokenClaimed = tokenClaimedOnThisChain[_msgSender()].amount;  
        require(mProof(_proof, leaf), "MorpherBridge: Merkle Proof failed. Please make sure you entered the correct claim limit.");
        require(_tokenClaimed + _numOfToken <= _claimLimit, "MorpherBridge: Token amount exceeds token deleted on linked chain."); 

        verifyUpdateDailyLimit(_msgSender(), _numOfToken);
        verifyUpdateMonthlyLimit(_msgSender(), _numOfToken);
        verifyUpdateYearlyLimit(_msgSender(), _numOfToken);        

        _chainTransfer(address(this), _tokenClaimed, _numOfToken); //instead of transferring it to the user, transfer it to the bridge itself
        emit TrustlessWithdrawFromSideChain(_msgSender(), _numOfToken);
        // Transfer the specified amount of DAI to this contract.
        // Approve the router to spend DAI.
        TransferHelper.safeApprove(state.morpherTokenAddress(), address(swapRouter), _numOfToken);

        // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: state.morpherTokenAddress(),
                tokenOut: IPeripheryImmutableState(address(swapRouter)).WETH9(),
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: _numOfToken,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        uint amountOut = swapRouter.exactInputSingle(params);
        //weth -> eth conversion
        IWETH9(IPeripheryImmutableState(address(swapRouter)).WETH9()).withdraw(amountOut);
        _finalOutput.transfer(amountOut);
    }

    function getWethWmaticAddress() public view returns (address) {
        return IPeripheryImmutableState(address(swapRouter)).WETH9();
    }

    // ------------------------------------------------------------------------
    // claimStagedTokens(...) former: trustlessTransferFromSideChain(uint256 _numOfToken, uint256 _claimLimit, bytes32[] memory _proof)
    // Performs a merkle proof on the number of token that have been burned by the user on the side chain.
    // If the number of token claimed on the main chain is less than the number of burned token on the side chain
    // the difference (or less) can be claimed on the main chain.
    // ------------------------------------------------------------------------
    function claimStagedTokensConvertAndSendForUser(address _usrAddr, uint256 _numOfToken, uint256 fee, address feeRecipient, uint256 _claimLimit, bytes32[] memory _proof, address payable _finalOutput, bytes32 _rootHash, bytes memory _userConfirmationSignature) public onlyRole(SIDECHAINOPERATOR_ROLE) returns(uint) {
        // msg.sender must approve this contract
        require(keccak256(abi.encodePacked(_numOfToken,_finalOutput,block.chainid)).toEthSignedMessageHash().recover(_userConfirmationSignature) == _usrAddr, "MorpherBridge: Users signature does not validate");
        updateSideChainMerkleRoot(_rootHash);
        bytes32 leaf = keccak256(abi.encodePacked(_usrAddr, _claimLimit, block.chainid));
        uint256 _tokenClaimed = tokenClaimedOnThisChain[_usrAddr].amount;  
        require(mProof(_proof, leaf), "MorpherBridge: Merkle Proof failed. Please make sure you entered the correct claim limit.");
        require(_tokenClaimed + _numOfToken <= _claimLimit, "MorpherBridge: Token amount exceeds token deleted on linked chain."); 

        verifyUpdateDailyLimit(_usrAddr, _numOfToken); //for usrAddr
        verifyUpdateMonthlyLimit(_usrAddr, _numOfToken);
        verifyUpdateYearlyLimit(_usrAddr, _numOfToken);        

        //mint the tokens
        tokenClaimedOnThisChain[_usrAddr].amount = _tokenClaimed + _numOfToken;
        tokenClaimedOnThisChain[_usrAddr].lastTransferAt = block.timestamp;
        MorpherToken(state.morpherTokenAddress()).mint(address(this), _numOfToken);
        emit TrustlessWithdrawFromSideChain(_usrAddr, _numOfToken);

        /**
         * Transfer the Fee away
         */
        MorpherToken(state.morpherTokenAddress()).transfer(feeRecipient, fee);
        
        
        uint convertTokens = _numOfToken - fee;


        // Transfer the specified amount of DAI to this contract.
        // Approve the router to spend DAI.
        TransferHelper.safeApprove(state.morpherTokenAddress(), address(swapRouter), convertTokens);

        // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: state.morpherTokenAddress(),
                tokenOut: IPeripheryImmutableState(address(swapRouter)).WETH9(),
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: convertTokens,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        uint amountOut = swapRouter.exactInputSingle(params);

        //weth -> eth conversion
        IWETH9(IPeripheryImmutableState(address(swapRouter)).WETH9()).withdraw(amountOut);
        _finalOutput.transfer(amountOut);
        emit WithdrawalSuccess(_finalOutput, amountOut, true);
        return amountOut;
    }

    // ------------------------------------------------------------------------
    // claimStagedTokens(...) former: trustlessTransferFromSideChain(uint256 _numOfToken, uint256 _claimLimit, bytes32[] memory _proof)
    // Performs a merkle proof on the number of token that have been burned by the user on the side chain.
    // If the number of token claimed on the main chain is less than the number of burned token on the side chain
    // the difference (or less) can be claimed on the main chain.
    // ------------------------------------------------------------------------
    function claimStagedTokensAndSendForUser(address _usrAddr, uint256 _numOfToken, uint256 fee, address feeRecipient, uint256 _claimLimit, bytes32[] memory _proof, address payable _finalOutput, bytes32 _rootHash, bytes memory _userConfirmationSignature) public onlyRole(SIDECHAINOPERATOR_ROLE) returns(uint) {
        // msg.sender must approve this contract
        require(keccak256(abi.encodePacked(_numOfToken,_finalOutput,block.chainid)).toEthSignedMessageHash().recover(_userConfirmationSignature) == _usrAddr, "MorpherBridge: Users signature does not validate");
        updateSideChainMerkleRoot(_rootHash);
        bytes32 leaf = keccak256(abi.encodePacked(_usrAddr, _claimLimit, block.chainid));
        uint256 _tokenClaimed = tokenClaimedOnThisChain[_usrAddr].amount;  
        require(mProof(_proof, leaf), "MorpherBridge: Merkle Proof failed. Please make sure you entered the correct claim limit.");
        require(_tokenClaimed + _numOfToken <= _claimLimit, "MorpherBridge: Token amount exceeds token deleted on linked chain."); 

        verifyUpdateDailyLimit(_usrAddr, _numOfToken); //for usrAddr
        verifyUpdateMonthlyLimit(_usrAddr, _numOfToken);
        verifyUpdateYearlyLimit(_usrAddr, _numOfToken);        

        //mint the tokens
        tokenClaimedOnThisChain[_usrAddr].amount = _tokenClaimed + _numOfToken;
        tokenClaimedOnThisChain[_usrAddr].lastTransferAt = block.timestamp;
        MorpherToken(state.morpherTokenAddress()).mint(address(this), _numOfToken);
        emit TrustlessWithdrawFromSideChain(_usrAddr, _numOfToken);

        /**
         * Transfer the Fee away
         */
        MorpherToken(state.morpherTokenAddress()).transfer(feeRecipient, fee);
        
        
        uint convertTokens = _numOfToken - fee;


        // Transfer the specified amount
        MorpherToken(state.morpherTokenAddress()).transfer( _finalOutput, convertTokens);
        
        emit WithdrawalSuccess(_finalOutput, convertTokens, false);
        return convertTokens;
    }
    
    // ------------------------------------------------------------------------
    // _chainTransfer(address _address, uint256 _tokenClaimed, uint256 _numOfToken)
    // Creates token on the chain for the user after proving their distruction on the 
    // linked chain has been proven before 
    // ------------------------------------------------------------------------
    function _chainTransfer(address _address, uint256 _tokenClaimed, uint256 _numOfToken) private {
        tokenClaimedOnThisChain[_address].amount = _tokenClaimed + _numOfToken;
        tokenClaimedOnThisChain[_address].lastTransferAt = block.timestamp;
        MorpherToken(state.morpherTokenAddress()).mint(_address, _numOfToken);
    }
        
    // ------------------------------------------------------------------------
    // claimFailedTransferToSidechain(uint256 _wrongSideChainBalance, bytes32[] memory _proof)
    // If token sent to side chain were not credited to the user on the side chain within inactivityPeriod
    // they can reclaim the token on the main chain by submitting the proof that their
    // side chain balance is less than the number of token sent from main chain.
    // ------------------------------------------------------------------------
    function claimFailedTransferToSidechain(uint256 _wrongSideChainBalance, bytes32[] memory _proof, uint256 _targetChainId) public userNotBlocked {
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender(), _wrongSideChainBalance));
        require(block.timestamp > tokenSentToLinkedChain[_msgSender()][_targetChainId].lastTransferAt + inactivityPeriod, "MorpherBridge: Failed deposits can only be claimed after inactivity period.");
        require(_wrongSideChainBalance < tokenSentToLinkedChain[_msgSender()][_targetChainId].amount, "MorpherBridge: Other chain credit is greater equal to wrongSideChainBalance.");
       
        require(mProof(_proof, leaf), "MorpherBridge: Merkle Proof failed. Enter total amount of deposits on side chain.");
 
        uint256 _claimAmount = tokenSentToLinkedChain[_msgSender()][_targetChainId].amount - _wrongSideChainBalance;
        tokenSentToLinkedChain[_msgSender()][_targetChainId].amount -=  _claimAmount;
        tokenSentToLinkedChain[_msgSender()][_targetChainId].lastTransferAt = block.timestamp;
        verifyUpdateDailyLimit(_msgSender(), _claimAmount);
        verifyUpdateMonthlyLimit(_msgSender(), _claimAmount);
        verifyUpdateYearlyLimit(_msgSender(), _claimAmount);         
        MorpherToken(state.morpherTokenAddress()).mint(_msgSender(), _claimAmount);
        emit ClaimFailedTransferToSidechain(_msgSender(), _claimAmount);
    }

    // ------------------------------------------------------------------------
    // recoverPositionFromInactivity former recoverPositionFromSideChain(bytes32[] memory _proof, bytes32 _leaf, bytes32 _marketId, uint256 _timeStamp, uint256 _longShares, uint256 _shortShares, uint256 _meanEntryPrice, uint256 _meanEntrySpread, uint256 _meanEntryLeverage)
    // Failsafe against side chain operator becoming inactive or withholding Times (Time withhold attack).
    // After 72 hours of no update of the side chain merkle root users can withdraw their last recorded
    // positions from side chain to main chain. Overwrites eventually existing position on main chain.
    // ------------------------------------------------------------------------
    function recoverPositionFromInactivity(
        bytes32[] memory _proof,
        bytes32 _leaf,
        bytes32 _marketId,
        uint256 _timeStamp,
        uint256 _longShares,
        uint256 _shortShares,
        uint256 _meanEntryPrice,
        uint256 _meanEntrySpread,
        uint256 _meanEntryLeverage,
        uint256 _liquidationPrice
        ) public sideChainInactive userNotBlocked onlyRecoveryEnabled {
        require(_leaf == MorpherTradeEngine(state.morpherTradeEngineAddress()).getPositionHash(_msgSender(), _marketId, _timeStamp, _longShares, _shortShares, _meanEntryPrice, _meanEntrySpread, _meanEntryLeverage, _liquidationPrice), "MorpherBridge: leaf does not equal position hash.");
        require(claimFromInactivity[_leaf] == false, "MorpherBridge: Position already transferred.");
        require(mProof(_proof,_leaf) == true, "MorpherBridge: Merkle proof failed.");
        claimFromInactivity[_leaf] = true;
        //todo: double positions clashing? 
        MorpherTradeEngine(state.morpherTradeEngineAddress()).setPosition(_msgSender(), _marketId, _timeStamp, _longShares, _shortShares, _meanEntryPrice, _meanEntrySpread, _meanEntryLeverage, _liquidationPrice);
        emit PositionRecoveryFromSideChain(_msgSender(), _leaf);
        // Remark: After resuming operations side chain operator has 72 hours to sync and eliminate transferred positions on side chain to avoid double spend
    }

    // ------------------------------------------------------------------------
    // recoverTokenFromInactivity - former recoverTokenFromSideChain(bytes32[] memory _proof, bytes32 _leaf, uint256 _balance)
    // Failsafe against side chain operator becoming inactive or withholding times (time withhold attack).
    // After 72 hours of no update of the side chain merkle root users can withdraw their last recorded
    // token balance from side chain to main chain.
    // ------------------------------------------------------------------------
    function recoverTokenFromInactivity(bytes32[] memory _proof, bytes32 _leaf, uint256 _balance) public sideChainInactive userNotBlocked onlyRecoveryEnabled {
        // Require side chain root hash not set on Mainchain for more than 72 hours (=3 days)
        require(_leaf == getBalanceHash(_msgSender(), _balance), "MorpherBridge: Wrong balance.");
        require(claimFromInactivity[_leaf] == false, "MorpherBridge: Token already transferred.");
        require(mProof(_proof,_leaf) == true, "MorpherBridge: Merkle proof failed.");
        claimFromInactivity[_leaf] = true;

        verifyUpdateDailyLimit(_msgSender(), _balance);
        verifyUpdateMonthlyLimit(_msgSender(), _balance);
        verifyUpdateYearlyLimit(_msgSender(), _balance); 
        
        _chainTransfer(_msgSender(), tokenClaimedOnThisChain[_msgSender()].amount, _balance);
        emit TokenRecoveryFromSideChain(_msgSender(), _leaf);
        // Remark: Side chain operator must adjust side chain balances for token recoveries before restarting operations to avoid double spend
    }

    // ------------------------------------------------------------------------
    // mProof(bytes32[] memory _proof, bytes32 _leaf)
    // Computes merkle proof against the root hash of the sidechain stored in Morpher state
    // ------------------------------------------------------------------------
    function mProof(bytes32[] memory _proof, bytes32 _leaf) public view returns(bool _isTrue) {
        return MerkleProofUpgradeable.verify(_proof, withdrawalData.merkleRoot, _leaf);
    }

    function getBalanceHash(address _address, uint256 _balance) public pure returns (bytes32 _hash) {
        return keccak256(abi.encodePacked(_address, _balance));
    }

    function getAndIncreaseBridgeNonce() internal returns (uint256) {
        bridgeNonce++;
        return bridgeNonce;
    }

    receive() external payable {
        //needed to convert the weth to eth and send to user
    }
}

//SPDX-License-Identifier: GPLv3
pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./MorpherAccessControl.sol";
import "./MorpherState.sol";


contract MorpherUserBlocking is Initializable {

    mapping(address => bool) public userIsBlocked;
    MorpherState state;

    bytes32 public constant ADMINISTRATOR_ROLE = keccak256("ADMINISTRATOR_ROLE");
    bytes32 public constant USERBLOCKINGADMIN_ROLE = keccak256("USERBLOCKINGADMIN_ROLE");

    event ChangeUserBlocked(address _user, bool _oldIsBlocked, bool _newIsBlocked);
    event ChangedAddressAllowedToAddBlockedUsersAddress(address _oldAddress, address _newAddress);

    function initialize(address _state) public initializer {
        state = MorpherState(_state);
    }

    modifier onlyAdministrator() {
        require(MorpherAccessControl(state.morpherAccessControlAddress()).hasRole(ADMINISTRATOR_ROLE, msg.sender), "UserBlocking: Only Administrator can call this function");
        _;
    }

    modifier onlyAllowedUsers() {
        require(MorpherAccessControl(state.morpherAccessControlAddress()).hasRole(ADMINISTRATOR_ROLE, msg.sender) || MorpherAccessControl(state.morpherAccessControlAddress()).hasRole(USERBLOCKINGADMIN_ROLE, msg.sender), "UserBlocking: Only White-Listed Users can call this function");
        _;
    }

    function setUserBlocked(address _user, bool _isBlocked) public onlyAllowedUsers {
        emit ChangeUserBlocked(_user, userIsBlocked[_user], _isBlocked);
        userIsBlocked[_user] = _isBlocked;
    }
}

//SPDX-License-Identifier: GPLv3
pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import "./MorpherState.sol";
import "./MorpherToken.sol";
import "./MorpherStaking.sol";
import "./MorpherUserBlocking.sol";
import "./MorpherMintingLimiter.sol";
import "./MorpherAccessControl.sol";

// ----------------------------------------------------------------------------------
// Tradeengine of the Morpher platform
// Creates and processes orders, and computes the state change of portfolio.
// Needs writing/reading access to/from Morpher State. Order objects are stored locally,
// portfolios are stored in state.
// ----------------------------------------------------------------------------------

contract MorpherTradeEngine is Initializable, ContextUpgradeable {
    MorpherState public morpherState;

    /**
     * Known Roles to Trade Engine
     */
    
    bytes32 public constant ADMINISTRATOR_ROLE = keccak256("ADMINISTRATOR_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    bytes32 public constant POSITIONADMIN_ROLE = keccak256("POSITIONADMIN_ROLE"); //can set and modify positions

// ----------------------------------------------------------------------------
// Precision of prices and leverage
// ----------------------------------------------------------------------------
    uint256 constant PRECISION = 10**8;
    uint256 public orderNonce;
    bytes32 public lastOrderId;
    uint256 public deployedTimeStamp;

    bool public escrowOpenOrderEnabled;

    struct PriceLock {
        uint lockedPrice;
    }
    //we're locking positions in for this price at a market marketId;
    mapping(bytes32 => PriceLock) public priceLockDeactivatedMarket;


// ----------------------------------------------------------------------------
// Order struct contains all order specific varibles. Variables are completed
// during processing of trade. State changes are saved in the order struct as
// well, since local variables would lead to stack to deep errors *sigh*.
// ----------------------------------------------------------------------------
    struct order {
        address userId;
        bytes32 marketId;
        uint256 closeSharesAmount;
        uint256 openMPHTokenAmount;
        bool tradeDirection; // true = long, false = short
        uint256 liquidationTimestamp;
        uint256 marketPrice;
        uint256 marketSpread;
        uint256 orderLeverage;
        uint256 timeStamp;
        uint256 orderEscrowAmount;
        OrderModifier modifyPosition;
    }

    struct OrderModifier {
        uint256 longSharesOrder;
        uint256 shortSharesOrder;
        uint256 balanceDown;
        uint256 balanceUp;
        uint256 newLongShares;
        uint256 newShortShares;
        uint256 newMeanEntryPrice;
        uint256 newMeanEntrySpread;
        uint256 newMeanEntryLeverage;
        uint256 newLiquidationPrice;
    }


    mapping(bytes32 => order) public orders;

     // ----------------------------------------------------------------------------
    // Position struct records virtual futures
    // ----------------------------------------------------------------------------
    struct position {
        uint256 lastUpdated;
        uint256 longShares;
        uint256 shortShares;
        uint256 meanEntryPrice;
        uint256 meanEntrySpread;
        uint256 meanEntryLeverage;
        uint256 liquidationPrice;
        bytes32 positionHash;
    }

    // ----------------------------------------------------------------------------
    // A portfolio is an address specific collection of postions
    // ----------------------------------------------------------------------------
    mapping(address => mapping(bytes32 => position)) public portfolio;

    // ----------------------------------------------------------------------------
    // Record all addresses that hold a position of a market, needed for clean stock splits
    // ----------------------------------------------------------------------------
    struct hasExposure {
        uint256 maxMappingIndex;
        mapping(address => uint256) index;
        mapping(uint256 => address) addy;
    }

    mapping(bytes32 => hasExposure) public exposureByMarket;

// ----------------------------------------------------------------------------
// Events
// Order created/processed events are fired by MorpherOracle.
// ----------------------------------------------------------------------------

    event PositionLiquidated(
        address indexed _address,
        bytes32 indexed _marketId,
        bool _longPosition,
        uint256 _timeStamp,
        uint256 _marketPrice,
        uint256 _marketSpread
    );

    event OrderCancelled(
        bytes32 indexed _orderId,
        address indexed _address
    );

    event OrderIdRequested(
        bytes32 _orderId,
        address indexed _address,
        bytes32 indexed _marketId,
        uint256 _closeSharesAmount,
        uint256 _openMPHTokenAmount,
        bool _tradeDirection,
        uint256 _orderLeverage
    );

    event OrderProcessed(
        bytes32 _orderId,
        uint256 _marketPrice,
        uint256 _marketSpread,
        uint256 _liquidationTimestamp,
        uint256 _timeStamp,
        uint256 _newLongShares,
        uint256 _newShortShares,
        uint256 _newAverageEntry,
        uint256 _newAverageSpread,
        uint256 _newAverageLeverage,
        uint256 _liquidationPrice
    );

    event PositionUpdated(
        address _userId,
        bytes32 _marketId,
        uint256 _timeStamp,
        uint256 _newLongShares,
        uint256 _newShortShares,
        uint256 _newMeanEntryPrice,
        uint256 _newMeanEntrySpread,
        uint256 _newMeanEntryLeverage,
        uint256 _newLiquidationPrice,
        uint256 _mint,
        uint256 _burn
    );

    event SetPosition(
        bytes32 indexed positionHash,
        address indexed sender,
        bytes32 indexed marketId,
        uint256 timeStamp,
        uint256 longShares,
        uint256 shortShares,
        uint256 meanEntryPrice,
        uint256 meanEntrySpread,
        uint256 meanEntryLeverage,
        uint256 liquidationPrice
    );

    
    event EscrowPaid(bytes32 orderId, address user, uint escrowAmount);
    event EscrowReturned(bytes32 orderId, address user, uint escrowAmount);

    event LinkState(address _address);
    
    event LockedPriceForClosingPositions(bytes32 _marketId, uint256 _price);

    function initialize(address _stateAddress, bool _escrowOpenOrderEnabled, uint256 _deployedTimestampOverride) public initializer {
        ContextUpgradeable.__Context_init();

        morpherState = MorpherState(_stateAddress);
        escrowOpenOrderEnabled = _escrowOpenOrderEnabled;
        deployedTimeStamp = _deployedTimestampOverride > 0 ? _deployedTimestampOverride : block.timestamp;
    }

    modifier onlyRole(bytes32 role) {
        require(MorpherAccessControl(morpherState.morpherAccessControlAddress()).hasRole(role, _msgSender()), "MorpherTradeEngine: Permission denied.");
        _;
    }


// ----------------------------------------------------------------------------
// Administrative functions
// Set state address, get administrator address
// ----------------------------------------------------------------------------

    function setMorpherState(address _stateAddress) public onlyRole(ADMINISTRATOR_ROLE) {
        morpherState = MorpherState(_stateAddress);
        emit LinkState(_stateAddress);
    }

    function setEscrowOpenOrderEnabled(bool _isEnabled) public onlyRole(ADMINISTRATOR_ROLE) {
        escrowOpenOrderEnabled = _isEnabled;
    }
    
    function paybackEscrow(bytes32 _orderId) private {
        //pay back the escrow to the user so he has it back on his balance/**
        if(orders[_orderId].orderEscrowAmount > 0) {
            //checks effects interaction
            uint256 paybackAmount = orders[_orderId].orderEscrowAmount;
            orders[_orderId].orderEscrowAmount = 0;
            MorpherToken(morpherState.morpherTokenAddress()).mint(orders[_orderId].userId, paybackAmount);
            emit EscrowReturned(_orderId, orders[_orderId].userId, paybackAmount);
        }
    }

    function buildupEscrow(bytes32 _orderId, uint256 _amountInMPH) private {
        if(escrowOpenOrderEnabled && _amountInMPH > 0) {
            MorpherToken(morpherState.morpherTokenAddress()).burn(orders[_orderId].userId, _amountInMPH);
            emit EscrowPaid(_orderId, orders[_orderId].userId, _amountInMPH);
            orders[_orderId].orderEscrowAmount = _amountInMPH;
        }
    }


    function validateClosedMarketOrderConditions(address _address, bytes32 _marketId, uint256 _closeSharesAmount, uint256 _openMPHTokenAmount, bool _tradeDirection ) internal view {
        //markets active? Still tradeable?
        if(_openMPHTokenAmount > 0) {
            require(morpherState.getMarketActive(_marketId) == true, "MorpherTradeEngine: market unknown or currently not enabled for trading.");
        } else {
            //we're just closing a position, but it needs a forever price locked in if market is not active
            //the user needs to close his complete position
            if(morpherState.getMarketActive(_marketId) == false) {
                require(getDeactivatedMarketPrice(_marketId) > 0, "MorpherTradeEngine: Can't close a position, market not active and closing price not locked");
                if(_tradeDirection) {
                    //long
                    require(_closeSharesAmount == portfolio[_address][_marketId].longShares, "MorpherTradeEngine: Deactivated market order needs all shares to be closed");
                } else {
                    //short
                    require(_closeSharesAmount == portfolio[_address][_marketId].longShares, "MorpherTradeEngine: Deactivated market order needs all shares to be closed");
                }
            }
        }
    }

    //wrapper for stack too deep errors
    function validateClosedMarketOrder(bytes32 _orderId) internal view {
         validateClosedMarketOrderConditions(orders[_orderId].userId, orders[_orderId].marketId, orders[_orderId].closeSharesAmount, orders[_orderId].openMPHTokenAmount, orders[_orderId].tradeDirection);
    }

// ----------------------------------------------------------------------------
// requestOrderId(address _address, bytes32 _marketId, bool _closeSharesAmount, uint256 _openMPHTokenAmount, bool _tradeDirection, uint256 _orderLeverage)
// Creates a new order object with unique orderId and assigns order information.
// Must be called by MorpherOracle contract.
// ----------------------------------------------------------------------------

    function requestOrderId(
        address _address,
        bytes32 _marketId,
        uint256 _closeSharesAmount,
        uint256 _openMPHTokenAmount,
        bool _tradeDirection,
        uint256 _orderLeverage
        ) public onlyRole(ORACLE_ROLE) returns (bytes32 _orderId) {
            
        require(_orderLeverage >= PRECISION, "MorpherTradeEngine: leverage too small. Leverage precision is 1e8");
        require(_orderLeverage <= morpherState.getMaximumLeverage(), "MorpherTradeEngine: leverage exceeds maximum allowed leverage.");

        validateClosedMarketOrderConditions(_address, _marketId, _closeSharesAmount, _openMPHTokenAmount, _tradeDirection);

        //request limits
        //@todo: fix request limit: 3 requests per block

        /**
         * The user can't partially close a position and open another one with MPH
         */
        if(_openMPHTokenAmount > 0) {

            if(_tradeDirection) {
                //long
                require(_closeSharesAmount == portfolio[_address][_marketId].shortShares, "MorpherTradeEngine: Can't partially close a position and open another one in opposite direction");
            } else {
                //short
                require(_closeSharesAmount == portfolio[_address][_marketId].longShares, "MorpherTradeEngine: Can't partially close a position and open another one in opposite direction");
            }
        }

        orderNonce++;
        _orderId = keccak256(
            abi.encodePacked(
                _address,
                block.number,
                _marketId,
                _closeSharesAmount,
                _openMPHTokenAmount,
                _tradeDirection,
                _orderLeverage,
                orderNonce
                )
            );
        lastOrderId = _orderId;
        orders[_orderId].userId = _address;
        orders[_orderId].marketId = _marketId;
        orders[_orderId].closeSharesAmount = _closeSharesAmount;
        orders[_orderId].openMPHTokenAmount = _openMPHTokenAmount;
        orders[_orderId].tradeDirection = _tradeDirection;
        orders[_orderId].orderLeverage = _orderLeverage;
        emit OrderIdRequested(
            _orderId,
            _address,
            _marketId,
            _closeSharesAmount,
            _openMPHTokenAmount,
            _tradeDirection,
            _orderLeverage
        );

        /**
         * put the money in escrow here if given MPH to open an order
         * - also, can only close positions if in shares, so it will
         * definitely trigger a mint there.
         * The money must be put in escrow even though we have an existing position
         */
        buildupEscrow(_orderId, _openMPHTokenAmount);

        return _orderId;
    }

// ----------------------------------------------------------------------------
// Getter functions for orders, shares, and positions
// ----------------------------------------------------------------------------

    function getOrder(bytes32 _orderId) public view returns (
        address _userId,
        bytes32 _marketId,
        uint256 _closeSharesAmount,
        uint256 _openMPHTokenAmount,
        uint256 _marketPrice,
        uint256 _marketSpread,
        uint256 _orderLeverage
        ) {
        return(
            orders[_orderId].userId,
            orders[_orderId].marketId,
            orders[_orderId].closeSharesAmount,
            orders[_orderId].openMPHTokenAmount,
            orders[_orderId].marketPrice,
            orders[_orderId].marketSpread,
            orders[_orderId].orderLeverage
            );
    }

    function setDeactivatedMarketPrice(bytes32 _marketId, uint256 _price) public onlyRole(ADMINISTRATOR_ROLE) {
         priceLockDeactivatedMarket[_marketId].lockedPrice = _price;
        emit LockedPriceForClosingPositions(_marketId, _price);

    }

    function getDeactivatedMarketPrice(bytes32 _marketId) public view returns(uint256) {
        return priceLockDeactivatedMarket[_marketId].lockedPrice;
    }

// ----------------------------------------------------------------------------
// liquidate(bytes32 _orderId)
// Checks for bankruptcy of position between its last update and now
// Time check is necessary to avoid two consecutive / unorderded liquidations
// ----------------------------------------------------------------------------

    function liquidate(bytes32 _orderId) private {
        address _address = orders[_orderId].userId;
        bytes32 _marketId = orders[_orderId].marketId;
        uint256 _liquidationTimestamp = orders[_orderId].liquidationTimestamp;
        if (_liquidationTimestamp > portfolio[_address][ _marketId].lastUpdated) {
            if (portfolio[_address][_marketId].longShares > 0) {
                setPosition(
                    _address,
                    _marketId,
                    orders[_orderId].timeStamp,
                    0,
                    portfolio[_address][ _marketId].shortShares,
                    0,
                    0,
                    PRECISION,
                    0);
                emit PositionLiquidated(
                    _address,
                    _marketId,
                    true,
                    orders[_orderId].timeStamp,
                    orders[_orderId].marketPrice,
                    orders[_orderId].marketSpread
                );
            }
            if (portfolio[_address][_marketId].shortShares > 0) {
                setPosition(
                    _address,
                    _marketId,
                    orders[_orderId].timeStamp,
                    portfolio[_address][_marketId].longShares,
                    0,
                    0,
                    0,
                    PRECISION,
                    0
                );
                emit PositionLiquidated(
                    _address,
                    _marketId,
                    false,
                    orders[_orderId].timeStamp,
                    orders[_orderId].marketPrice,
                    orders[_orderId].marketSpread
                );
            }
        }
    }

// ----------------------------------------------------------------------------
// processOrder(bytes32 _orderId, uint256 _marketPrice, uint256 _marketSpread, uint256 _liquidationTimestamp, uint256 _timeStamp)
// ProcessOrder receives the price/spread/liqidation information from the Oracle and
// triggers the processing of the order. If successful, processOrder updates the portfolio state.
// Liquidation time check is necessary to avoid two consecutive / unorderded liquidations
// ----------------------------------------------------------------------------

    function processOrder(
        bytes32 _orderId,
        uint256 _marketPrice,
        uint256 _marketSpread,
        uint256 _liquidationTimestamp,
        uint256 _timeStampInMS
        ) public onlyRole(ORACLE_ROLE) returns (position memory) {
        require(orders[_orderId].userId != address(0), "MorpherTradeEngine: unable to process, order has been deleted.");
        require(_marketPrice > 0, "MorpherTradeEngine: market priced at zero. Buy order cannot be processed.");
        require(_marketPrice >= _marketSpread, "MorpherTradeEngine: market price lower then market spread. Order cannot be processed.");
        
        orders[_orderId].marketPrice = _marketPrice;
        orders[_orderId].marketSpread = _marketSpread;
        orders[_orderId].timeStamp = _timeStampInMS;
        orders[_orderId].liquidationTimestamp = _liquidationTimestamp;
        
        /**
        * If the market is deactivated, then override the price with the locked in market price
        * if the price wasn't locked in: error out.
        */
        if(morpherState.getMarketActive(orders[_orderId].marketId) == false) {
            validateClosedMarketOrder(_orderId);
            orders[_orderId].marketPrice = getDeactivatedMarketPrice(orders[_orderId].marketId);
        }
        
        // Check if previous position on that market was liquidated
        if (_liquidationTimestamp > portfolio[orders[_orderId].userId][ orders[_orderId].marketId].lastUpdated) {
            liquidate(_orderId);
        } else {
            require(!MorpherUserBlocking(morpherState.morpherUserBlockingAddress()).userIsBlocked(orders[_orderId].userId), "MorpherTradeEngine: User is blocked from Trading");
        }
    

        paybackEscrow(_orderId);

        if (orders[_orderId].tradeDirection) {
            processBuyOrder(_orderId);
        } else {
            processSellOrder(_orderId);
        }

        address _address = orders[_orderId].userId;
        bytes32 _marketId = orders[_orderId].marketId;
        delete orders[_orderId];
        emit OrderProcessed(
            _orderId,
            _marketPrice,
            _marketSpread,
            _liquidationTimestamp,
            _timeStampInMS,
            portfolio[_address][_marketId].longShares,
            portfolio[_address][_marketId].shortShares,
            portfolio[_address][_marketId].meanEntryPrice,
            portfolio[_address][_marketId].meanEntrySpread,
            portfolio[_address][_marketId].meanEntryLeverage,
            portfolio[_address][_marketId].liquidationPrice
        );

        return portfolio[_address][_marketId];
    }

// ----------------------------------------------------------------------------
// function cancelOrder(bytes32 _orderId, address _address)
// Users or Administrator can delete pending orders before the callback went through
// ----------------------------------------------------------------------------
    function cancelOrder(bytes32 _orderId, address _address) public onlyRole(ORACLE_ROLE) {
        require(_address == orders[_orderId].userId || MorpherAccessControl(morpherState.morpherAccessControlAddress()).hasRole(ADMINISTRATOR_ROLE, _address), "MorpherTradeEngine: only Administrator or user can cancel an order.");
        require(orders[_orderId].userId != address(0), "MorpherTradeEngine: unable to process, order does not exist.");

        /**
         * Pay back any escrow there
         */
        paybackEscrow(_orderId);

        delete orders[_orderId];
        emit OrderCancelled(_orderId, _address);
    }

// ----------------------------------------------------------------------------
// shortShareValue / longShareValue compute the value of a virtual future
// given current price/spread/leverage of the market and mean price/spread/leverage
// at the beginning of the trade
// ----------------------------------------------------------------------------
    function shortShareValue(
        uint256 _positionAveragePrice,
        uint256 _positionAverageLeverage,
        uint256 _positionTimeStampInMs,
        uint256 _marketPrice,
        uint256 _marketSpread,
        uint256 _orderLeverage,
        bool _sell
        ) public view returns (uint256 _shareValue) {

        uint256 _averagePrice = _positionAveragePrice;
        uint256 _averageLeverage = _positionAverageLeverage;

        if (_positionAverageLeverage < PRECISION) {
            // Leverage can never be less than 1. Fail safe for empty positions, i.e. undefined _positionAverageLeverage
            _averageLeverage = PRECISION;
        }
        if (_sell == false) {
            // New short position
            // It costs marketPrice + marketSpread to build up a new short position
            _averagePrice = _marketPrice;
	        // This is the average Leverage
	        _averageLeverage = _orderLeverage;
        }
        if (
            getLiquidationPrice(_averagePrice, _averageLeverage, false, _positionTimeStampInMs) <= _marketPrice
            ) {
	        // Position is worthless
            _shareValue = 0;
        } else {
            // The regular share value is 2x the entry price minus the current price for short positions.
            _shareValue = _averagePrice * (PRECISION + _averageLeverage) / PRECISION;
            _shareValue = _shareValue - _marketPrice * _averageLeverage / PRECISION;
            if (_sell == true) {
                // We have to reduce the share value by the average spread (i.e. the average expense to build up the position)
                // and reduce the value further by the spread for selling.
                _shareValue = _shareValue- _marketSpread * _averageLeverage / PRECISION;
                uint256 _marginInterest = calculateMarginInterest(_averagePrice, _averageLeverage, _positionTimeStampInMs);
                if (_marginInterest <= _shareValue) {
                    _shareValue = _shareValue - (_marginInterest);
                } else {
                    _shareValue = 0;
                }
            } else {
                // If a new short position is built up each share costs value + spread
                _shareValue = _shareValue + (_marketSpread * (_orderLeverage) / (PRECISION));
            }
        }
      
        return _shareValue;
    }

    function longShareValue(
        uint256 _positionAveragePrice,
        uint256 _positionAverageLeverage,
        uint256 _positionTimeStampInMs,
        uint256 _marketPrice,
        uint256 _marketSpread,
        uint256 _orderLeverage,
        bool _sell
        ) public view returns (uint256 _shareValue) {

        uint256 _averagePrice = _positionAveragePrice;
        uint256 _averageLeverage = _positionAverageLeverage;

        if (_positionAverageLeverage < PRECISION) {
            // Leverage can never be less than 1. Fail safe for empty positions, i.e. undefined _positionAverageLeverage
            _averageLeverage = PRECISION;
        }
        if (_sell == false) {
            // New long position
            // It costs marketPrice + marketSpread to build up a new long position
            _averagePrice = _marketPrice;
	        // This is the average Leverage
	        _averageLeverage = _orderLeverage;
        }
        if (
            _marketPrice <= getLiquidationPrice(_averagePrice, _averageLeverage, true, _positionTimeStampInMs)
            ) {
	        // Position is worthless
            _shareValue = 0;
        } else {
            _shareValue = _averagePrice * (_averageLeverage - PRECISION) / (PRECISION);
            // The regular share value is market price times leverage minus entry price times entry leverage minus one.
            _shareValue = (_marketPrice * _averageLeverage / PRECISION) - _shareValue;
            if (_sell == true) {
                // We sell a long and have to correct the shareValue with the averageSpread and the currentSpread for selling.
                _shareValue = _shareValue - (_marketSpread * _averageLeverage / PRECISION);
                
                uint256 _marginInterest = calculateMarginInterest(_averagePrice, _averageLeverage, _positionTimeStampInMs);
                if (_marginInterest <= _shareValue) {
                    _shareValue = _shareValue - (_marginInterest);
                } else {
                    _shareValue = 0;
                }
            } else {
                // We buy a new long position and have to pay the spread
                _shareValue = _shareValue + (_marketSpread * (_orderLeverage) / (PRECISION));
            }
        }
        return _shareValue;
    }

// ----------------------------------------------------------------------------
// calculateMarginInterest(uint256 _averagePrice, uint256 _averageLeverage, uint256 _positionTimeStamp)
// Calculates the interest for leveraged positions
// ----------------------------------------------------------------------------


    function calculateMarginInterest(uint256 _averagePrice, uint256 _averageLeverage, uint256 _positionTimeStampInMs) public view returns (uint256) {
        uint _marginInterest;
        if (_positionTimeStampInMs / 1000 < deployedTimeStamp) {
            _positionTimeStampInMs = deployedTimeStamp / 1000;
        }
        uint interestRate = MorpherStaking(morpherState.morpherStakingAddress()).getInterestRate(_positionTimeStampInMs / 1000);
        _marginInterest = _averagePrice * (_averageLeverage - PRECISION);
        _marginInterest = _marginInterest * ((block.timestamp - (_positionTimeStampInMs / 1000)) / 86400) + 1;
        _marginInterest = ((_marginInterest * interestRate) / PRECISION) / PRECISION;
        return _marginInterest;
    }

// ----------------------------------------------------------------------------
// processBuyOrder(bytes32 _orderId)
// Converts orders specified in virtual shares to orders specified in Morpher token
// and computes the number of short shares that are sold and long shares that are bought.
// long shares are bought only if the order amount exceeds all open short positions
// ----------------------------------------------------------------------------

    function processBuyOrder(bytes32 _orderId) private {
        if (orders[_orderId].closeSharesAmount > 0) {
            //calcualte the balanceUp/down first
            //then reopen the position with MPH amount

             // Investment was specified in shares
            if (orders[_orderId].closeSharesAmount <= portfolio[orders[_orderId].userId][ orders[_orderId].marketId].shortShares) {
                // Partial closing of short position
                orders[_orderId].modifyPosition.shortSharesOrder = orders[_orderId].closeSharesAmount;
            } else {
                // Closing of entire short position
                orders[_orderId].modifyPosition.shortSharesOrder = portfolio[orders[_orderId].userId][ orders[_orderId].marketId].shortShares;
            }
        }

        //calculate the long shares, but only if the old position is completely closed out (if none exist shortSharesOrder = 0)
        if(
            orders[_orderId].modifyPosition.shortSharesOrder == portfolio[orders[_orderId].userId][ orders[_orderId].marketId].shortShares && 
            orders[_orderId].openMPHTokenAmount > 0
        ) {
            orders[_orderId].modifyPosition.longSharesOrder = orders[_orderId].openMPHTokenAmount / (
                longShareValue(
                    orders[_orderId].marketPrice,
                    orders[_orderId].orderLeverage,
                    block.timestamp * (1000),
                    orders[_orderId].marketPrice,
                    orders[_orderId].marketSpread,
                    orders[_orderId].orderLeverage,
                    false
            ));
        }

        // Investment equals number of shares now.
        if (orders[_orderId].modifyPosition.shortSharesOrder > 0) {
            closeShort(_orderId);
        }
        if (orders[_orderId].modifyPosition.longSharesOrder > 0) {
            openLong(_orderId);
        }
    }

// ----------------------------------------------------------------------------
// processSellOrder(bytes32 _orderId)
// Converts orders specified in virtual shares to orders specified in Morpher token
// and computes the number of long shares that are sold and short shares that are bought.
// short shares are bought only if the order amount exceeds all open long positions
// ----------------------------------------------------------------------------

    function processSellOrder(bytes32 _orderId) private {
        if (orders[_orderId].closeSharesAmount > 0) {
            //calcualte the balanceUp/down first
            //then reopen the position with MPH amount

            // Investment was specified in shares
            if (orders[_orderId].closeSharesAmount <= portfolio[orders[_orderId].userId][ orders[_orderId].marketId].longShares) {
                // Partial closing of long position
                orders[_orderId].modifyPosition.longSharesOrder = orders[_orderId].closeSharesAmount;
            } else {
                // Closing of entire long position
                orders[_orderId].modifyPosition.longSharesOrder = portfolio[orders[_orderId].userId][ orders[_orderId].marketId].longShares;
            }
        }

        if(
            orders[_orderId].modifyPosition.longSharesOrder == portfolio[orders[_orderId].userId][ orders[_orderId].marketId].longShares && 
            orders[_orderId].openMPHTokenAmount > 0
        ) {
        orders[_orderId].modifyPosition.shortSharesOrder = orders[_orderId].openMPHTokenAmount / (
                    shortShareValue(
                        orders[_orderId].marketPrice,
                        orders[_orderId].orderLeverage,
                        block.timestamp * (1000),
                        orders[_orderId].marketPrice,
                        orders[_orderId].marketSpread,
                        orders[_orderId].orderLeverage,
                        false
                ));
        }
        // Investment equals number of shares now.
        if (orders[_orderId].modifyPosition.longSharesOrder > 0) {
            closeLong(_orderId);
        }
        if (orders[_orderId].modifyPosition.shortSharesOrder > 0) {
            openShort(_orderId);
        }
    }

// ----------------------------------------------------------------------------
// openLong(bytes32 _orderId)
// Opens a new long position and computes the new resulting average entry price/spread/leverage.
// Computation is broken down to several instructions for readability.
// ----------------------------------------------------------------------------
    function openLong(bytes32 _orderId) private {
        address _userId = orders[_orderId].userId;
        bytes32 _marketId = orders[_orderId].marketId;

        uint256 _newMeanSpread;
        uint256 _newMeanLeverage;

        // Existing position is virtually liquidated and reopened with current marketPrice
        // orders[_orderId].modifyPosition.newMeanEntryPrice = orders[_orderId].marketPrice;
        // _factorLongShares is a factor to adjust the existing longShares via virtual liqudiation and reopening at current market price

        uint256 _factorLongShares = portfolio[_userId][ _marketId].meanEntryLeverage;
        if (_factorLongShares < PRECISION) {
            _factorLongShares = PRECISION;
        }
        _factorLongShares = _factorLongShares - (PRECISION);
        _factorLongShares = _factorLongShares * (portfolio[_userId][ _marketId].meanEntryPrice) / (orders[_orderId].marketPrice);
        if (portfolio[_userId][ _marketId].meanEntryLeverage > _factorLongShares) {
            _factorLongShares = portfolio[_userId][ _marketId].meanEntryLeverage - (_factorLongShares);
        } else {
            _factorLongShares = 0;
        }

        uint256 _adjustedLongShares = _factorLongShares * (portfolio[_userId][ _marketId].longShares) / (PRECISION);

        // _newMeanLeverage is the weighted leverage of the existing position and the new position
        _newMeanLeverage = portfolio[_userId][ _marketId].meanEntryLeverage * (_adjustedLongShares);
        _newMeanLeverage = _newMeanLeverage + (orders[_orderId].orderLeverage * (orders[_orderId].modifyPosition.longSharesOrder));
        _newMeanLeverage = _newMeanLeverage / (_adjustedLongShares + (orders[_orderId].modifyPosition.longSharesOrder));

        // _newMeanSpread is the weighted spread of the existing position and the new position
        _newMeanSpread = portfolio[_userId][ _marketId].meanEntrySpread * (portfolio[_userId][ _marketId].longShares);
        _newMeanSpread = _newMeanSpread + (orders[_orderId].marketSpread * (orders[_orderId].modifyPosition.longSharesOrder));
        _newMeanSpread = _newMeanSpread / (_adjustedLongShares + (orders[_orderId].modifyPosition.longSharesOrder));

        orders[_orderId].modifyPosition.balanceDown = orders[_orderId].modifyPosition.longSharesOrder * (orders[_orderId].marketPrice) + (
            orders[_orderId].modifyPosition.longSharesOrder * (orders[_orderId].marketSpread) * (orders[_orderId].orderLeverage) / (PRECISION)
        );
        orders[_orderId].modifyPosition.balanceUp = 0;
        orders[_orderId].modifyPosition.newLongShares = _adjustedLongShares + (orders[_orderId].modifyPosition.longSharesOrder);
        orders[_orderId].modifyPosition.newShortShares = portfolio[_userId][ _marketId].shortShares;
        orders[_orderId].modifyPosition.newMeanEntryPrice = orders[_orderId].marketPrice;
        orders[_orderId].modifyPosition.newMeanEntrySpread = _newMeanSpread;
        orders[_orderId].modifyPosition.newMeanEntryLeverage = _newMeanLeverage;

        setPositionInState(_orderId);
    }
// ----------------------------------------------------------------------------
// closeLong(bytes32 _orderId)
// Closes an existing long position. Average entry price/spread/leverage do not change.
// ----------------------------------------------------------------------------
     function closeLong(bytes32 _orderId) private {
        address _userId = orders[_orderId].userId;
        bytes32 _marketId = orders[_orderId].marketId;
        uint256 _newLongShares  = portfolio[_userId][ _marketId].longShares - (orders[_orderId].modifyPosition.longSharesOrder);
        uint256 _balanceUp = calculateBalanceUp(_orderId);
        uint256 _newMeanEntry;
        uint256 _newMeanSpread;
        uint256 _newMeanLeverage;

        if (orders[_orderId].modifyPosition.longSharesOrder == portfolio[_userId][ _marketId].longShares) {
            _newMeanEntry = 0;
            _newMeanSpread = 0;
            _newMeanLeverage = PRECISION;
        } else {
            _newMeanEntry = portfolio[_userId][ _marketId].meanEntryPrice;
	        _newMeanSpread = portfolio[_userId][ _marketId].meanEntrySpread;
	        _newMeanLeverage = portfolio[_userId][ _marketId].meanEntryLeverage;
            resetTimestampInOrderToLastUpdated(_orderId);
        }

        orders[_orderId].modifyPosition.balanceDown = 0;
        orders[_orderId].modifyPosition.balanceUp = _balanceUp;
        orders[_orderId].modifyPosition.newLongShares = _newLongShares;
        orders[_orderId].modifyPosition.newShortShares = portfolio[_userId][ _marketId].shortShares;
        orders[_orderId].modifyPosition.newMeanEntryPrice = _newMeanEntry;
        orders[_orderId].modifyPosition.newMeanEntrySpread = _newMeanSpread;
        orders[_orderId].modifyPosition.newMeanEntryLeverage = _newMeanLeverage;

        setPositionInState(_orderId);
    }

event ResetTimestampInOrder(bytes32 _orderId, uint oldTimestamp, uint newTimestamp);
function resetTimestampInOrderToLastUpdated(bytes32 _orderId) internal {
    address userId = orders[_orderId].userId;
    bytes32 marketId = orders[_orderId].marketId;
    uint lastUpdated = portfolio[userId][ marketId].lastUpdated;
    emit ResetTimestampInOrder(_orderId, orders[_orderId].timeStamp, lastUpdated);
    orders[_orderId].timeStamp = lastUpdated;
}

// ----------------------------------------------------------------------------
// closeShort(bytes32 _orderId)
// Closes an existing short position. Average entry price/spread/leverage do not change.
// ----------------------------------------------------------------------------
function calculateBalanceUp(bytes32 _orderId) private view returns (uint256 _balanceUp) {
        address _userId = orders[_orderId].userId;
        bytes32 _marketId = orders[_orderId].marketId;
        uint256 _shareValue;

        if (orders[_orderId].tradeDirection == false) { //we are selling our long shares
            _balanceUp = orders[_orderId].modifyPosition.longSharesOrder;
            _shareValue = longShareValue(
                portfolio[_userId][ _marketId].meanEntryPrice,
                portfolio[_userId][ _marketId].meanEntryLeverage,
                portfolio[_userId][ _marketId].lastUpdated,
                orders[_orderId].marketPrice,
                orders[_orderId].marketSpread,
                portfolio[_userId][ _marketId].meanEntryLeverage,
                true
            );
        } else { //we are going long, we are selling our short shares
            _balanceUp = orders[_orderId].modifyPosition.shortSharesOrder;
            _shareValue = shortShareValue(
                portfolio[_userId][ _marketId].meanEntryPrice,
                portfolio[_userId][ _marketId].meanEntryLeverage,
                portfolio[_userId][ _marketId].lastUpdated,
                orders[_orderId].marketPrice,
                orders[_orderId].marketSpread,
                portfolio[_userId][ _marketId].meanEntryLeverage,
                true
            );
        }
        return _balanceUp * (_shareValue); 
    }

    function closeShort(bytes32 _orderId) private {
        address _userId = orders[_orderId].userId;
        bytes32 _marketId = orders[_orderId].marketId;
        uint256 _newMeanEntry;
        uint256 _newMeanSpread;
        uint256 _newMeanLeverage;
        uint256 _newShortShares = portfolio[_userId][ _marketId].shortShares - (orders[_orderId].modifyPosition.shortSharesOrder);
        uint256 _balanceUp = calculateBalanceUp(_orderId);
        
        if (orders[_orderId].modifyPosition.shortSharesOrder == portfolio[_userId][ _marketId].shortShares) {
            _newMeanEntry = 0;
            _newMeanSpread = 0;
	        _newMeanLeverage = PRECISION;
        } else {
            _newMeanEntry = portfolio[_userId][ _marketId].meanEntryPrice;
	        _newMeanSpread = portfolio[_userId][ _marketId].meanEntrySpread;
	        _newMeanLeverage = portfolio[_userId][ _marketId].meanEntryLeverage;

            /**
             * we need the timestamp of the old order for partial closes, not the new one
             */
            resetTimestampInOrderToLastUpdated(_orderId);
        }

        orders[_orderId].modifyPosition.balanceDown = 0;
        orders[_orderId].modifyPosition.balanceUp = _balanceUp;
        orders[_orderId].modifyPosition.newLongShares = portfolio[orders[_orderId].userId][ orders[_orderId].marketId].longShares;
        orders[_orderId].modifyPosition.newShortShares = _newShortShares;
        orders[_orderId].modifyPosition.newMeanEntryPrice = _newMeanEntry;
        orders[_orderId].modifyPosition.newMeanEntrySpread = _newMeanSpread;
        orders[_orderId].modifyPosition.newMeanEntryLeverage = _newMeanLeverage;

        setPositionInState(_orderId);
    }

// ----------------------------------------------------------------------------
// openShort(bytes32 _orderId)
// Opens a new short position and computes the new resulting average entry price/spread/leverage.
// Computation is broken down to several instructions for readability.
// ----------------------------------------------------------------------------
    function openShort(bytes32 _orderId) private {
        address _userId = orders[_orderId].userId;
        bytes32 _marketId = orders[_orderId].marketId;

        uint256 _newMeanSpread;
        uint256 _newMeanLeverage;
        //
        // Existing position is virtually liquidated and reopened with current marketPrice
        // orders[_orderId].modifyPosition.newMeanEntryPrice = orders[_orderId].marketPrice;
        // _factorShortShares is a factor to adjust the existing shortShares via virtual liqudiation and reopening at current market price

        uint256 _factorShortShares = portfolio[_userId][ _marketId].meanEntryLeverage;
        if (_factorShortShares < PRECISION) {
            _factorShortShares = PRECISION;
        }
        _factorShortShares = _factorShortShares + (PRECISION);
        _factorShortShares = _factorShortShares * (portfolio[_userId][ _marketId].meanEntryPrice) / (orders[_orderId].marketPrice);
        if (portfolio[_userId][ _marketId].meanEntryLeverage < _factorShortShares) {
            _factorShortShares = _factorShortShares - (portfolio[_userId][ _marketId].meanEntryLeverage);
        } else {
            _factorShortShares = 0;
        }

        uint256 _adjustedShortShares = _factorShortShares * (portfolio[_userId][ _marketId].shortShares) / (PRECISION);

        // _newMeanLeverage is the weighted leverage of the existing position and the new position
        _newMeanLeverage = portfolio[_userId][ _marketId].meanEntryLeverage * (_adjustedShortShares);
        _newMeanLeverage = _newMeanLeverage + (orders[_orderId].orderLeverage * (orders[_orderId].modifyPosition.shortSharesOrder));
        _newMeanLeverage = _newMeanLeverage / (_adjustedShortShares + (orders[_orderId].modifyPosition.shortSharesOrder));

        // _newMeanSpread is the weighted spread of the existing position and the new position
        _newMeanSpread = portfolio[_userId][ _marketId].meanEntrySpread * (portfolio[_userId][ _marketId].shortShares);
        _newMeanSpread = _newMeanSpread + (orders[_orderId].marketSpread * (orders[_orderId].modifyPosition.shortSharesOrder));
        _newMeanSpread = _newMeanSpread / (_adjustedShortShares + (orders[_orderId].modifyPosition.shortSharesOrder));

        orders[_orderId].modifyPosition.balanceDown = orders[_orderId].modifyPosition.shortSharesOrder * (orders[_orderId].marketPrice) + (
            orders[_orderId].modifyPosition.shortSharesOrder * (orders[_orderId].marketSpread) * (orders[_orderId].orderLeverage) / (PRECISION)
        );
        orders[_orderId].modifyPosition.balanceUp = 0;
        orders[_orderId].modifyPosition.newLongShares = portfolio[_userId][ _marketId].longShares;
        orders[_orderId].modifyPosition.newShortShares = _adjustedShortShares + (orders[_orderId].modifyPosition.shortSharesOrder);
        orders[_orderId].modifyPosition.newMeanEntryPrice = orders[_orderId].marketPrice;
        orders[_orderId].modifyPosition.newMeanEntrySpread = _newMeanSpread;
        orders[_orderId].modifyPosition.newMeanEntryLeverage = _newMeanLeverage;

        setPositionInState(_orderId);
    }

    function computeLiquidationPrice(bytes32 _orderId) public returns(uint256 _liquidationPrice) {
        orders[_orderId].modifyPosition.newLiquidationPrice = 0;
        if (orders[_orderId].modifyPosition.newLongShares > 0) {
            orders[_orderId].modifyPosition.newLiquidationPrice = getLiquidationPrice(orders[_orderId].modifyPosition.newMeanEntryPrice, orders[_orderId].modifyPosition.newMeanEntryLeverage, true, orders[_orderId].timeStamp);
        }
        if (orders[_orderId].modifyPosition.newShortShares > 0) {
            orders[_orderId].modifyPosition.newLiquidationPrice = getLiquidationPrice(orders[_orderId].modifyPosition.newMeanEntryPrice, orders[_orderId].modifyPosition.newMeanEntryLeverage, false, orders[_orderId].timeStamp);
        }
        return orders[_orderId].modifyPosition.newLiquidationPrice;
    }

    function getLiquidationPrice(uint256 _newMeanEntryPrice, uint256 _newMeanEntryLeverage, bool _long, uint _positionTimestampInMs) public view returns (uint256) {
        uint _liquidationPrice;
        uint marginInterest = calculateMarginInterest(_newMeanEntryPrice, _newMeanEntryLeverage, _positionTimestampInMs);
        uint adjustedMarginInterest = marginInterest * PRECISION / _newMeanEntryLeverage;
        if (_long == true) {
            _liquidationPrice = _newMeanEntryPrice * (_newMeanEntryLeverage - (PRECISION)) / (_newMeanEntryLeverage);
            _liquidationPrice += adjustedMarginInterest;
        } else {
            _liquidationPrice = _newMeanEntryPrice * (_newMeanEntryLeverage + (PRECISION)) / (_newMeanEntryLeverage);
            _liquidationPrice -= adjustedMarginInterest;
        }
        return _liquidationPrice;
    }

    
// ----------------------------------------------------------------------------
// setPositionInState(bytes32 _orderId)
// Updates the portfolio in Morpher State. Called by closeLong/closeShort/openLong/openShort
// ----------------------------------------------------------------------------
    function setPositionInState(bytes32 _orderId) private {
        require(MorpherToken(morpherState.morpherTokenAddress()).balanceOf(orders[_orderId].userId) + (orders[_orderId].modifyPosition.balanceUp) >= orders[_orderId].modifyPosition.balanceDown, "MorpherTradeEngine: insufficient funds.");
        computeLiquidationPrice(_orderId);
        // Net balanceUp and balanceDown
        if (orders[_orderId].modifyPosition.balanceUp > orders[_orderId].modifyPosition.balanceDown) {
            orders[_orderId].modifyPosition.balanceUp -= (orders[_orderId].modifyPosition.balanceDown);
            orders[_orderId].modifyPosition.balanceDown = 0;
        } else {
            orders[_orderId].modifyPosition.balanceDown -= (orders[_orderId].modifyPosition.balanceUp);
            orders[_orderId].modifyPosition.balanceUp = 0;
        }
        if (orders[_orderId].modifyPosition.balanceUp > 0) {
            MorpherToken(morpherState.morpherMintingLimiterAddress()).mint(orders[_orderId].userId, orders[_orderId].modifyPosition.balanceUp);
        }
        if (orders[_orderId].modifyPosition.balanceDown > 0) {
            MorpherToken(morpherState.morpherTokenAddress()).burn(orders[_orderId].userId, orders[_orderId].modifyPosition.balanceDown);
        }
        _setPosition(
            orders[_orderId].userId,
            orders[_orderId].marketId,
            orders[_orderId].timeStamp,
            orders[_orderId].modifyPosition.newLongShares,
            orders[_orderId].modifyPosition.newShortShares,
            orders[_orderId].modifyPosition.newMeanEntryPrice,
            orders[_orderId].modifyPosition.newMeanEntrySpread,
            orders[_orderId].modifyPosition.newMeanEntryLeverage,
            orders[_orderId].modifyPosition.newLiquidationPrice
        );
        emit PositionUpdated(
            orders[_orderId].userId,
            orders[_orderId].marketId,
            orders[_orderId].timeStamp,
            orders[_orderId].modifyPosition.newLongShares,
            orders[_orderId].modifyPosition.newShortShares,
            orders[_orderId].modifyPosition.newMeanEntryPrice,
            orders[_orderId].modifyPosition.newMeanEntrySpread,
            orders[_orderId].modifyPosition.newMeanEntryLeverage,
            orders[_orderId].modifyPosition.newLiquidationPrice,
            orders[_orderId].modifyPosition.balanceUp,
            orders[_orderId].modifyPosition.balanceDown
        );
    }

     function setPosition(
        address _address,
        bytes32 _marketId,
        uint256 _timeStamp,
        uint256 _longShares,
        uint256 _shortShares,
        uint256 _meanEntryPrice,
        uint256 _meanEntrySpread,
        uint256 _meanEntryLeverage,
        uint256 _liquidationPrice
    ) public onlyRole(POSITIONADMIN_ROLE) {
        _setPosition(_address,
        _marketId,
        _timeStamp,
        _longShares,
        _shortShares,
        _meanEntryPrice,
        _meanEntrySpread,
        _meanEntryLeverage,
        _liquidationPrice);
    }

     function _setPosition(
        address _address,
        bytes32 _marketId,
        uint256 _timeStamp,
        uint256 _longShares,
        uint256 _shortShares,
        uint256 _meanEntryPrice,
        uint256 _meanEntrySpread,
        uint256 _meanEntryLeverage,
        uint256 _liquidationPrice
    ) internal {
        portfolio[_address][_marketId].lastUpdated = _timeStamp;
        portfolio[_address][_marketId].longShares = _longShares;
        portfolio[_address][_marketId].shortShares = _shortShares;
        portfolio[_address][_marketId].meanEntryPrice = _meanEntryPrice;
        portfolio[_address][_marketId].meanEntrySpread = _meanEntrySpread;
        portfolio[_address][_marketId].meanEntryLeverage = _meanEntryLeverage;
        portfolio[_address][_marketId].liquidationPrice = _liquidationPrice;
        portfolio[_address][_marketId].positionHash = getPositionHash(
            _address,
            _marketId,
            _timeStamp,
            _longShares,
            _shortShares,
            _meanEntryPrice,
            _meanEntrySpread,
            _meanEntryLeverage,
            _liquidationPrice
        );
        if (_longShares > 0 || _shortShares > 0) {
            addExposureByMarket(_marketId, _address);
        } else {
            deleteExposureByMarket(_marketId, _address);
        }
        emit SetPosition(
            portfolio[_address][_marketId].positionHash,
            _address,
            _marketId,
            _timeStamp,
            _longShares,
            _shortShares,
            _meanEntryPrice,
            _meanEntrySpread,
            _meanEntryLeverage,
            _liquidationPrice
        );
    }

    function getPosition(address _address, bytes32 _marketId) public view returns (position memory) {
        return portfolio[_address][_marketId];
    }

    function getPositionHash(
        address _address,
        bytes32 _marketId,
        uint256 _timeStamp,
        uint256 _longShares,
        uint256 _shortShares,
        uint256 _meanEntryPrice,
        uint256 _meanEntrySpread,
        uint256 _meanEntryLeverage,
        uint256 _liquidationPrice
    ) public pure returns (bytes32 _hash) {
        return keccak256(
            abi.encodePacked(
                _address,
                _marketId,
                _timeStamp,
                _longShares,
                _shortShares,
                _meanEntryPrice,
                _meanEntrySpread,
                _meanEntryLeverage,
                _liquidationPrice
            )
        );
    }



    function addExposureByMarket(bytes32 _symbol, address _address) private {
        // Address must not be already recored
        uint256 _myExposureIndex = getExposureMappingIndex(_symbol, _address);
        if (_myExposureIndex == 0) {
            uint256 _maxMappingIndex = getMaxMappingIndex(_symbol) + (1);
            setMaxMappingIndex(_symbol, _maxMappingIndex);
            setExposureMapping(_symbol, _address, _maxMappingIndex);
        }
    }


    function deleteExposureByMarket(bytes32 _symbol, address _address) private {
        // Get my index in mapping
        uint256 _myExposureIndex = getExposureMappingIndex(_symbol, _address);
        // Get last element of mapping
        uint256 _lastIndex = getMaxMappingIndex(_symbol);
        address _lastAddress = getExposureMappingAddress(_symbol, _lastIndex);
        // If _myExposureIndex is greater than 0 (i.e. there is an exposure of that address on that market) delete it
        if (_myExposureIndex > 0) {
            // If _myExposureIndex is less than _lastIndex overwrite element at _myExposureIndex with element at _lastIndex in
            // deleted elements position.
            if (_myExposureIndex < _lastIndex) {
                setExposureMappingAddress(_symbol, _lastAddress, _myExposureIndex);
                setExposureMappingIndex(_symbol, _lastAddress, _myExposureIndex);
            }
            // Delete _lastIndex and _lastAddress element and reduce maxExposureIndex
            setExposureMappingAddress(_symbol, address(0), _lastIndex);
            setExposureMappingIndex(_symbol, _address, 0);
            // Shouldn't happen, but check that not empty
            if (_lastIndex > 0) {
                setMaxMappingIndex(_symbol, _lastIndex - (1));
            }
        }
    }

    
    function getMaxMappingIndex(bytes32 _marketId) public view returns(uint256 _maxMappingIndex) {
        return exposureByMarket[_marketId].maxMappingIndex;
    }

    function getExposureMappingIndex(bytes32 _marketId, address _address) public view returns(uint256 _mappingIndex) {
        return exposureByMarket[_marketId].index[_address];
    }

    function getExposureMappingAddress(bytes32 _marketId, uint256 _mappingIndex) public view returns(address _address) {
        return exposureByMarket[_marketId].addy[_mappingIndex];
    }

    function setMaxMappingIndex(bytes32 _marketId, uint256 _maxMappingIndex) private {
        exposureByMarket[_marketId].maxMappingIndex = _maxMappingIndex;
    }

    function setExposureMapping(bytes32 _marketId, address _address, uint256 _index) private {
        setExposureMappingIndex(_marketId, _address, _index);
        setExposureMappingAddress(_marketId, _address, _index);
    }

    function setExposureMappingIndex(bytes32 _marketId, address _address, uint256 _index) private {
        exposureByMarket[_marketId].index[_address] = _index;
    }

    function setExposureMappingAddress(bytes32 _marketId, address _address, uint256 _index) private {
        exposureByMarket[_marketId].addy[_index] = _address;
    }



}

//SPDX-License-Identifier: GPLv3
pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import "./MorpherAccessControl.sol";

contract MorpherToken is ERC20Upgradeable, ERC20PausableUpgradeable {

    MorpherAccessControl public morpherAccessControl;
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant ADMINISTRATOR_ROLE = keccak256("ADMINISTRATOR_ROLE");
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
    bytes32 public constant TRANSFERBLOCKED_ROLE = keccak256("TRANSFERBLOCKED_ROLE");
    bytes32 public constant POLYGONMINTER_ROLE = keccak256("POLYGONMINTER_ROLE");

    uint256 private _totalTokensOnOtherChain;
    uint256 private _totalTokensInPositions;
    bool private _restrictTransfers;

    event SetTotalTokensOnOtherChain(uint256 _oldValue, uint256 _newValue);
    event SetTotalTokensInPositions(uint256 _oldValue, uint256 _newValue);
    event SetRestrictTransfers(bool _oldValue, bool _newValue);

    function initialize(address _morpherAccessControl) public initializer {
        ERC20Upgradeable.__ERC20_init("Morpher", "MPH");
        morpherAccessControl = MorpherAccessControl(_morpherAccessControl);
    }

    modifier onlyRole(bytes32 role) {
        require(morpherAccessControl.hasRole(role, _msgSender()), "MorpherToken: Permission denied.");
        _;
    }

    // function getMorpherAccessControl() public view returns(address) {
    //     return address(morpherAccessControl);
    // }

    function setRestrictTransfers(bool restrictTransfers) public onlyRole(ADMINISTRATOR_ROLE) {
        emit SetRestrictTransfers(_restrictTransfers, restrictTransfers);
        _restrictTransfers = restrictTransfers;
    }

    function getRestrictTransfers() public view returns(bool) {
        return _restrictTransfers;
    }

    function setTotalTokensOnOtherChain(uint256 totalOnOtherChain) public onlyRole(ADMINISTRATOR_ROLE) {
        emit SetTotalTokensOnOtherChain(_totalTokensInPositions, totalOnOtherChain);
        _totalTokensOnOtherChain = totalOnOtherChain;
    }

    function getTotalTokensOnOtherChain() public view returns(uint256) {
        return _totalTokensOnOtherChain;
    }

    function setTotalInPositions(uint256 totalTokensInPositions) public onlyRole(ADMINISTRATOR_ROLE) {
        emit SetTotalTokensInPositions(_totalTokensInPositions, totalTokensInPositions);
        _totalTokensInPositions = totalTokensInPositions;
    }

    function getTotalTokensInPositions() public view returns(uint256) {
        return _totalTokensInPositions;
    }


    
    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return super.totalSupply() + _totalTokensOnOtherChain + _totalTokensInPositions;
    }

    function deposit(address user, bytes calldata depositData) external onlyRole(POLYGONMINTER_ROLE) {
        uint256 amount = abi.decode(depositData, (uint256));
        _mint(user, amount);
    }

    function withdraw(uint256 amount) external onlyRole(POLYGONMINTER_ROLE) {
        _burn(msg.sender, amount);
    }


    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) public virtual {
        require(morpherAccessControl.hasRole(MINTER_ROLE, _msgSender()), "MorpherToken: must have minter role to mint");
        _mint(to, amount);
    }

    /**
     * @dev Burns `amount` of tokens for `from`.
     *
     * See {ERC20-_burn}.
     *
     * Requirements:
     *
     * - the caller must have the `BURNER_ROLE`.
     */
    function burn(address from, uint256 amount) public virtual {
        require(morpherAccessControl.hasRole(BURNER_ROLE, _msgSender()), "MorpherToken: must have burner role to burn");
        _burn(from, amount);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(morpherAccessControl.hasRole(PAUSER_ROLE, _msgSender()), "MorpherToken: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(morpherAccessControl.hasRole(PAUSER_ROLE, _msgSender()), "MorpherToken: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20Upgradeable, ERC20PausableUpgradeable) {
        require(
            !_restrictTransfers || 
            morpherAccessControl.hasRole(TRANSFER_ROLE, _msgSender()) || 
            morpherAccessControl.hasRole(MINTER_ROLE, _msgSender()) || 
            morpherAccessControl.hasRole(BURNER_ROLE, _msgSender()) || 
            morpherAccessControl.hasRole(TRANSFER_ROLE, from)
            , "MorpherToken: Transfer denied");

        require(!morpherAccessControl.hasRole(TRANSFERBLOCKED_ROLE, _msgSender()), "MorpherToken: Transfer for User is blocked.");

        super._beforeTokenTransfer(from, to, amount);
    }
}

//SPDX-License-Identifier: GPLv3
pragma solidity 0.8.11;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "./MorpherToken.sol";
import "./MorpherTradeEngine.sol";

// ----------------------------------------------------------------------------------
// Data and token balance storage of the Morpher platform
// Writing access is only granted to platform contracts. The contract can be paused
// by an elected platform administrator (see MorpherGovernance) to perform protocol updates.
// ----------------------------------------------------------------------------------

contract MorpherState is Initializable, ContextUpgradeable  {

    address public morpherAccessControlAddress;
    address public morpherAirdropAddress;
    address public morpherBridgeAddress;
    address public morpherFaucetAddress;
    address public morpherGovernanceAddress;
    address public morpherMintingLimiterAddress;
    address public morpherOracleAddress;
    address payable public morpherStakingAddress;
    address public morpherTokenAddress;
    address public morpherTradeEngineAddress;
    address public morpherUserBlockingAddress;

    /**
     * Roles known to State
     */
    bytes32 public constant ADMINISTRATOR_ROLE = keccak256("ADMINISTRATOR_ROLE");
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
    bytes32 public constant PLATFORM_ROLE = keccak256("PLATFORM_ROLE");
 

    address public morpherRewards;
    uint256 public maximumLeverage; // Leverage precision is 1e8, maximum leverage set to 10 initially
    uint256 public constant PRECISION = 10**8;
    uint256 public constant DECIMALS = 18;
    uint256 public constant REWARDPERIOD = 1 days;

    uint256 public rewardBasisPoints;
    uint256 public lastRewardTime;

    bytes32 public sideChainMerkleRoot;
    uint256 public sideChainMerkleRootWrittenAtTime;

    // Set initial withdraw limit from sidechain to 20m token or 2% of initial supply
    uint256 public mainChainWithdrawLimit24;

    mapping(bytes32 => bool) private marketActive;

    // ----------------------------------------------------------------------------
    // Sidechain spam protection
    // ----------------------------------------------------------------------------

    mapping(address => uint256) private lastRequestBlock;
    mapping(address => uint256) private numberOfRequests;
    uint256 public numberOfRequestsLimit;

    // ----------------------------------------------------------------------------
    // Events
    // ----------------------------------------------------------------------------
    event OperatingRewardMinted(address indexed recipient, uint256 amount);

    event RewardsChange(address indexed rewardsAddress, uint256 indexed rewardsBasisPoints);
    event LastRewardTime(uint256 indexed rewardsTime);

   
    event MaximumLeverageChange(uint256 maxLeverage);
    event MarketActivated(bytes32 indexed activateMarket);
    event MarketDeActivated(bytes32 indexed deActivateMarket);


    modifier onlyRole(bytes32 role) {
        require(MorpherAccessControl(morpherAccessControlAddress).hasRole(role, _msgSender()), "MorpherState: Permission denied.");
        _;
    }



    modifier onlyBridge {
        require(msg.sender == morpherBridgeAddress, "MorpherState: Caller is not the Bridge. Aborting.");
        _;
    }

    modifier onlyMainChain {
        require(mainChain == true, "MorpherState: Can only be called on mainchain.");
        _;
    }

    bool mainChain;

    function initialize(bool _mainChain, address _morpherAccessControlAddress) public initializer {
        ContextUpgradeable.__Context_init();
        
        morpherAccessControlAddress = _morpherAccessControlAddress;
        mainChain = _mainChain;

        maximumLeverage = 10*PRECISION; // Leverage precision is 1e8, maximum leverage set to 10 initially
    }

    // ----------------------------------------------------------------------------
    // Setter/Getter functions for platform roles
    // ----------------------------------------------------------------------------

    event SetMorpherAccessControlAddress(address _oldAddress, address _newAddress);
    function setMorpherAccessControl(address _morpherAccessControlAddress) public onlyRole(ADMINISTRATOR_ROLE) {
        emit SetMorpherAccessControlAddress(morpherAccessControlAddress, _morpherAccessControlAddress);
        morpherAccessControlAddress = _morpherAccessControlAddress;
    }

    event SetMorpherAirdropAddress(address _oldAddress, address _newAddress);
    function setMorpherAirdrop(address _morpherAirdropAddress) public onlyRole(ADMINISTRATOR_ROLE) {
        emit SetMorpherAirdropAddress(morpherAirdropAddress, _morpherAirdropAddress);
        morpherAirdropAddress = _morpherAirdropAddress;
    }

    event SetMorpherBridgeAddress(address _oldAddress, address _newAddress);
    function setMorpherBridge(address _morpherBridgeAddress) public onlyRole(ADMINISTRATOR_ROLE) {
        emit SetMorpherBridgeAddress(morpherBridgeAddress, _morpherBridgeAddress);
        morpherBridgeAddress = _morpherBridgeAddress;
    }

    event SetMorpherFaucetAddress(address _oldAddress, address _newAddress);
    function setMorpherFaucet(address _morpherFaucetAddress) public onlyRole(ADMINISTRATOR_ROLE) {
        emit SetMorpherFaucetAddress(morpherFaucetAddress, _morpherFaucetAddress);
        morpherFaucetAddress = _morpherFaucetAddress;
    }

    event SetMorpherGovernanceAddress(address _oldAddress, address _newAddress);
    function setMorpherGovernance(address _morpherGovernanceAddress) public onlyRole(ADMINISTRATOR_ROLE) {
        emit SetMorpherGovernanceAddress(morpherGovernanceAddress, _morpherGovernanceAddress);
        morpherGovernanceAddress = _morpherGovernanceAddress;
    }

    event SetMorpherMintingLimiterAddress(address _oldAddress, address _newAddress);
    function setMorpherMintingLimiter(address _morpherMintingLimiterAddress) public onlyRole(ADMINISTRATOR_ROLE) {
        emit SetMorpherMintingLimiterAddress(morpherMintingLimiterAddress, _morpherMintingLimiterAddress);
        morpherMintingLimiterAddress = _morpherMintingLimiterAddress;
    }
    event SetMorpherOracleAddress(address _oldAddress, address _newAddress);
    function setMorpherOracle(address _morpherOracleAddress) public onlyRole(ADMINISTRATOR_ROLE) {
        emit SetMorpherOracleAddress(morpherOracleAddress, _morpherOracleAddress);
        morpherOracleAddress = _morpherOracleAddress;
    }

    event SetMorpherStakingAddress(address _oldAddress, address _newAddress);
    function setMorpherStaking(address payable _morpherStakingAddress) public onlyRole(ADMINISTRATOR_ROLE) {
        emit SetMorpherStakingAddress(morpherStakingAddress, _morpherStakingAddress);
        morpherStakingAddress = _morpherStakingAddress;
    }

    event SetMorpherTokenAddress(address _oldAddress, address _newAddress);
    function setMorpherToken(address _morpherTokenAddress) public onlyRole(ADMINISTRATOR_ROLE) {
        emit SetMorpherTokenAddress(morpherTokenAddress, _morpherTokenAddress);
        morpherTokenAddress = _morpherTokenAddress;
    }

    event SetMorpherTradeEngineAddress(address _oldAddress, address _newAddress);
    function setMorpherTradeEngine(address _morpherTradeEngineAddress) public onlyRole(ADMINISTRATOR_ROLE) {
        emit SetMorpherTradeEngineAddress(morpherTradeEngineAddress, _morpherTradeEngineAddress);
        morpherTradeEngineAddress = _morpherTradeEngineAddress;
    }

    event SetMorpherUserBlockingAddress(address _oldAddress, address _newAddress);
    function setMorpherUserBlocking(address _morpherUserBlockingAddress) public onlyRole(ADMINISTRATOR_ROLE) {
        emit SetMorpherUserBlockingAddress(morpherUserBlockingAddress, _morpherUserBlockingAddress);
        morpherUserBlockingAddress = _morpherUserBlockingAddress;
    }


    // ----------------------------------------------------------------------------
    // Setter/Getter functions for platform administration
    // ----------------------------------------------------------------------------

    function activateMarket(bytes32 _activateMarket) public onlyRole(ADMINISTRATOR_ROLE)  {
        marketActive[_activateMarket] = true;
        emit MarketActivated(_activateMarket);
    }

    function deActivateMarket(bytes32 _deActivateMarket) public onlyRole(ADMINISTRATOR_ROLE)  {
        marketActive[_deActivateMarket] = false;
        emit MarketDeActivated(_deActivateMarket);
    }

    function getMarketActive(bytes32 _marketId) public view returns(bool _active) {
        return marketActive[_marketId];
    }

    function setMaximumLeverage(uint256 _newMaximumLeverage) public onlyRole(ADMINISTRATOR_ROLE)  {
        require(_newMaximumLeverage > PRECISION, "MorpherState: Leverage precision is 1e8");
        maximumLeverage = _newMaximumLeverage;
        emit MaximumLeverageChange(_newMaximumLeverage);
    }

    function getMaximumLeverage() public view returns(uint256 _maxLeverage) {
        return maximumLeverage;
    }

    /**
     * Backwards compatibility functions
     */
    function getLastUpdated(address _address, bytes32 _marketHash) public view returns(uint) {
        return MorpherTradeEngine(morpherTradeEngineAddress).getPosition(_address, _marketHash).lastUpdated; 
    }

    function totalToken() public view returns(uint) {
        return MorpherToken(morpherTokenAddress).totalSupply();
    }

       function getPosition(
        address _address,
        bytes32 _marketId
    ) public view returns (
        uint256 _longShares,
        uint256 _shortShares,
        uint256 _meanEntryPrice,
        uint256 _meanEntrySpread,
        uint256 _meanEntryLeverage,
        uint256 _liquidationPrice
    ) {
        MorpherTradeEngine.position memory position = MorpherTradeEngine(morpherTradeEngineAddress).getPosition(_address, _marketId);
        return (
            position.longShares,
            position.shortShares,
            position.meanEntryPrice,
            position.meanEntrySpread,
            position.meanEntryLeverage,
            position.liquidationPrice
        );
    }

    
}

//SPDX-License-Identifier: GPLv3
pragma solidity 0.8.11;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import "./MorpherState.sol";
import "./MorpherUserBlocking.sol";
import "./MorpherToken.sol";

// ----------------------------------------------------------------------------------
// Staking Morpher Token generates interest
// The interest is set to 0.015% a day or ~5.475% in the first year
// Stakers will be able to vote on all ProtocolDecisions in MorpherGovernance (soon...)
// There is a lockup after staking or topping up (30 days) and a minimum stake (100k MPH)
// ----------------------------------------------------------------------------------

contract MorpherStaking is Initializable, ContextUpgradeable {

    MorpherState state;

    uint256 constant PRECISION = 10**8;
    uint256 constant INTERVAL  = 1 days;

    bytes32 constant public ADMINISTRATOR_ROLE = keccak256("ADMINISTRATOR_ROLE");
    bytes32 constant public STAKINGADMIN_ROLE = keccak256("STAKINGADMIN_ROLE");

    //mapping(address => uint256) private poolShares;
    //mapping(address => uint256) private lockup;

    uint256 public poolShareValue;
    uint256 public lastReward;
    uint256 public totalShares;
    //uint256 public interestRate = 15000; // 0.015% per day initially, diminishing returns over time
    struct InterestRate {
        uint256 validFrom;
        uint256 rate;
    }

    mapping(uint256 => InterestRate) public interestRates;
    uint256 public numInterestRates;

    uint256 public lockupPeriod; // to prevent tactical staking and ensure smooth governance
    uint256 public minimumStake; // 100k MPH minimum

    address public stakingAddress;
    bytes32 public marketIdStakingMPH; //STAKING_MPH

    struct PoolShares {
        uint256 numPoolShares;
        uint256 lockedUntil;
    }
    mapping(address => PoolShares) public poolShares;

// ----------------------------------------------------------------------------
// Events
// ----------------------------------------------------------------------------
    event SetInterestRate(uint256 newInterestRate);
    event InterestRateAdded(uint256 interestRate, uint256 validFromTimestamp);
    event InterestRateRateChanged(uint256 interstRateIndex, uint256 oldvalue, uint256 newValue);
    event InterestRateValidFromChanged(uint256 interstRateIndex, uint256 oldvalue, uint256 newValue);
    event SetLockupPeriod(uint256 newLockupPeriod);
    event SetMinimumStake(uint256 newMinimumStake);
    event LinkState(address stateAddress);
    
    event PoolShareValueUpdated(uint256 indexed lastReward, uint256 poolShareValue);
    event StakingRewardsMinted(uint256 indexed lastReward, uint256 delta);
    event Staked(address indexed userAddress, uint256 indexed amount, uint256 poolShares, uint256 lockedUntil);
    event Unstaked(address indexed userAddress, uint256 indexed amount, uint256 poolShares);
    
    
    modifier onlyRole(bytes32 role) {
        require(MorpherAccessControl(state.morpherAccessControlAddress()).hasRole(role, _msgSender()), "MorpherToken: Permission denied.");
        _;
    }

    modifier userNotBlocked {
        require(!MorpherUserBlocking(state.morpherUserBlockingAddress()).userIsBlocked(msg.sender), "MorpherStaking: User is blocked");
        _;
    }
    
    function initialize(address _morpherState) public initializer {
        ContextUpgradeable.__Context_init();

        state = MorpherState(_morpherState);
        
        lastReward = block.timestamp;
        lockupPeriod = 30 days; // to prevent tactical staking and ensure smooth governance
        minimumStake = 10**23; // 100k MPH minimum
        stakingAddress = 0x2222222222222222222222222222222222222222;
        marketIdStakingMPH = 0x9a31fdde7a3b1444b1befb10735dcc3b72cbd9dd604d2ff45144352bf0f359a6; //STAKING_MPH
        poolShareValue = PRECISION;
        emit SetLockupPeriod(lockupPeriod);
        emit SetMinimumStake(minimumStake);
        // missing: transferOwnership to Governance once deployed
    }

// ----------------------------------------------------------------------------
// updatePoolShareValue
// Updates the value of the Pool Shares and returns the new value.
// Staking rewards are linear, there is no compound interest.
// ----------------------------------------------------------------------------
    
    function updatePoolShareValue() public returns (uint256 _newPoolShareValue) {
        if (block.timestamp >= lastReward + INTERVAL) {
            uint256 _numOfIntervals = block.timestamp - lastReward / INTERVAL;
            poolShareValue = poolShareValue + (_numOfIntervals * interestRate());
            lastReward = lastReward + (_numOfIntervals * (INTERVAL));
            emit PoolShareValueUpdated(lastReward, poolShareValue);
        }
        //mintStakingRewards(); //burning/minting does not influence this
        return poolShareValue;        
    }

// ----------------------------------------------------------------------------
// Staking rewards are minted if necessary
// ----------------------------------------------------------------------------

    // function mintStakingRewards() private {
    //     uint256 _targetBalance = poolShareValue * (totalShares);
    //     if (MorpherToken(state.morpherTokenAddress()).balanceOf(stakingAddress) < _targetBalance) {
    //         // If there are not enough token held by the contract, mint them
    //         uint256 _delta = _targetBalance - (MorpherToken(state.morpherTokenAddress()).balanceOf(stakingAddress));
    //         MorpherToken(state.morpherTokenAddress()).mint(stakingAddress, _delta);
    //         emit StakingRewardsMinted(lastReward, _delta);
    //     }
    // }

// ----------------------------------------------------------------------------
// stake(uint256 _amount)
// User specifies an amount they intend to stake. Pool Shares are issued accordingly
// and the _amount is transferred to the staking contract
// ----------------------------------------------------------------------------

    function stake(uint256 _amount) public userNotBlocked returns (uint256 _poolShares) {
        require(MorpherToken(state.morpherTokenAddress()).balanceOf(msg.sender) >= _amount, "MorpherStaking: insufficient MPH token balance");
        updatePoolShareValue();
        _poolShares = _amount / (poolShareValue);
        uint _numOfShares = poolShares[msg.sender].numPoolShares;
        require(minimumStake <= _numOfShares + _poolShares * poolShareValue, "MorpherStaking: stake amount lower than minimum stake");
        MorpherToken(state.morpherTokenAddress()).burn(msg.sender, _poolShares * (poolShareValue));
        totalShares = totalShares + (_poolShares);
        poolShares[msg.sender].numPoolShares = _numOfShares + _poolShares;
        poolShares[msg.sender].lockedUntil = block.timestamp + lockupPeriod;
        emit Staked(msg.sender, _amount, _poolShares, block.timestamp + (lockupPeriod));
        return _poolShares;
    }

// ----------------------------------------------------------------------------
// unstake(uint256 _amount)
// User specifies number of Pool Shares they want to unstake. 
// Pool Shares get deleted and the user receives their MPH plus interest
// ----------------------------------------------------------------------------

    function unstake(uint256 _numOfShares) public userNotBlocked returns (uint256 _amount) {
        uint256 _numOfExistingShares = poolShares[msg.sender].numPoolShares;
        require(_numOfShares <= _numOfExistingShares, "MorpherStaking: insufficient pool shares");

        uint256 lockedInUntil = poolShares[msg.sender].lockedUntil;
        require(block.timestamp >= lockedInUntil, "MorpherStaking: cannot unstake before lockup expiration");
        updatePoolShareValue();
        poolShares[msg.sender].numPoolShares = poolShares[msg.sender].numPoolShares - _numOfShares;
        totalShares = totalShares - _numOfShares;
        _amount = _numOfShares * poolShareValue;
        MorpherToken(state.morpherTokenAddress()).mint(msg.sender, _amount);
        emit Unstaked(msg.sender, _amount, _numOfShares);
        return _amount;
    }

// ----------------------------------------------------------------------------
// Administrative functions
// ----------------------------------------------------------------------------

    function setMorpherStateAddress(address _stateAddress) public onlyRole(ADMINISTRATOR_ROLE) {
        state = MorpherState(_stateAddress);
        emit LinkState(_stateAddress);
    }

    /**
    Interest rate
     */
    function setInterestRate(uint256 _interestRate) public onlyRole(STAKINGADMIN_ROLE) {
        addInterestRate(_interestRate, block.timestamp);
    }

/**
    fallback function in case the old tradeengine asks for the current interest rate
 */
    function interestRate() public view returns (uint256) {
        //start with the last one, as its most likely the last active one, no need to run through the whole map
        if(numInterestRates == 0) {
            return 0;
        }
        for(uint256 i = numInterestRates - 1; i >= 0; i--) {
            if(interestRates[i].validFrom <= block.timestamp) {
                return interestRates[i].rate;
            }
        }
        return 0;
    }

    function addInterestRate(uint _rate, uint _validFrom) public onlyRole(STAKINGADMIN_ROLE) {
        require(numInterestRates == 0 || interestRates[numInterestRates-1].validFrom < _validFrom, "MorpherStaking: Interest Rate Valid From must be later than last interestRate");
        //omitting rate sanity checks here. It should always be smaller than 100% (100000000) but I'll leave that to the common sense of the admin.
        updatePoolShareValue();
        interestRates[numInterestRates].validFrom = _validFrom;
        interestRates[numInterestRates].rate = _rate;
        numInterestRates++;
        emit InterestRateAdded(_rate, _validFrom);
    }

    function changeInterestRateValue(uint256 _numInterestRate, uint256 _rate) public onlyRole(STAKINGADMIN_ROLE) {
        emit InterestRateRateChanged(_numInterestRate, interestRates[_numInterestRate].rate, _rate);
        updatePoolShareValue();
        interestRates[_numInterestRate].rate = _rate;
    }
    function changeInterestRateValidFrom(uint256 _numInterestRate, uint256 _validFrom) public onlyRole(STAKINGADMIN_ROLE) {
        emit InterestRateValidFromChanged(_numInterestRate, interestRates[_numInterestRate].validFrom, _validFrom);
        require(numInterestRates > _numInterestRate, "MorpherStaking: Interest Rate Does not exist!");
        require(
            (_numInterestRate == 0 && numInterestRates-1 > 0 && interestRates[_numInterestRate+1].validFrom > _validFrom) || //we change the first one and there exist more than one
            (_numInterestRate > 0 && _numInterestRate == numInterestRates-1 && interestRates[_numInterestRate - 1].validFrom < _validFrom) || //we changed the last one
            (_numInterestRate > 0 && _numInterestRate < numInterestRates-1 && interestRates[_numInterestRate - 1].validFrom < _validFrom && interestRates[_numInterestRate + 1].validFrom > _validFrom),
            "MorpherStaking: validFrom cannot be smaller than previous Interest Rate or larger than next Interest Rate"
            );
        updatePoolShareValue();
        interestRates[_numInterestRate].validFrom = _validFrom;
    }

     function getInterestRate(uint256 _positionTimestamp) public view returns(uint256) {
        uint256 sumInterestRatesWeighted = 0;
        uint256 startingTimestamp = 0;
        
        for(uint256 i = 0; i < numInterestRates; i++) {
            if(i == numInterestRates-1 || interestRates[i+1].validFrom > block.timestamp) {
                //reached last interest rate
                sumInterestRatesWeighted = sumInterestRatesWeighted + (interestRates[i].rate * (block.timestamp - interestRates[i].validFrom));
                if(startingTimestamp == 0) {
                    startingTimestamp = interestRates[i].validFrom;
                }
                break; //in case there are more in the future
            } else {
                //only take interest rates after the position was created
                if(interestRates[i+1].validFrom > _positionTimestamp) {
                    sumInterestRatesWeighted = sumInterestRatesWeighted + (interestRates[i].rate * (interestRates[i+1].validFrom - interestRates[i].validFrom));
                    if(interestRates[i].validFrom <= _positionTimestamp) {
                        startingTimestamp = interestRates[i].validFrom;
                    }
                }
            } 
        }
        uint interestRateInternal = sumInterestRatesWeighted / (block.timestamp - startingTimestamp);
        return interestRateInternal;

    }

    function setLockupPeriodRate(uint256 _lockupPeriod) public onlyRole(STAKINGADMIN_ROLE) {
        lockupPeriod = _lockupPeriod;
        emit SetLockupPeriod(_lockupPeriod);
    }
    
    function setMinimumStake(uint256 _minimumStake) public onlyRole(STAKINGADMIN_ROLE) {
        minimumStake = _minimumStake;
        emit SetMinimumStake(_minimumStake);
    }

// ----------------------------------------------------------------------------
// Getter functions
// ----------------------------------------------------------------------------

    function getTotalPooledValue() public view returns (uint256 _totalPooled) {
        // Only accurate if poolShareValue is up to date
        return poolShareValue * (totalShares);
    }

    function getStake(address _address) public view returns (uint256 _poolShares) {
        return poolShares[_address].numPoolShares;
    }

    function getStakeValue(address _address) public view returns(uint256 _value, uint256 _lastUpdate) {
        // Only accurate if poolShareValue is up to date
        return (getStake(_address) * (poolShareValue), lastReward);
    }
}

//SPDX-License-Identifier: GPLv3
pragma solidity 0.8.11;

import "./MorpherAccessControl.sol";
import "./MorpherState.sol";
import "./MorpherTradeEngine.sol";
import "./MorpherToken.sol";


contract MorpherMintingLimiter {

    bytes32 constant public ADMINISTRATOR_ROLE = keccak256("ADMINISTRATOR_ROLE");

    uint256 public mintingLimitPerUser;
    uint256 public mintingLimitDaily;
    uint256 public timeLockingPeriod;

    mapping(address => uint256) public escrowedTokens;
    mapping(address => uint256) public lockedUntil;
    mapping(uint256 => uint256) public dailyMintedTokens;

    address tradeEngineAddress; 
    MorpherState state;

    event MintingEscrowed(address _user, uint256 _tokenAmount);
    event EscrowReleased(address _user, uint256 _tokenAmount);
    event MintingDenied(address _user, uint256 _tokenAmount);
    event MintingLimitUpdatedPerUser(uint256 _mintingLimitOld, uint256 _mintingLimitNew);
    event MintingLimitUpdatedDaily(uint256 _mintingLimitOld, uint256 _mintingLimitNew);
    event TimeLockPeriodUpdated(uint256 _timeLockPeriodOld, uint256 _timeLockPeriodNew);
    event TradeEngineAddressSet(address _tradeEngineAddress);
    event DailyMintedTokensReset();

    modifier onlyTradeEngine() {
        require(msg.sender == state.morpherTradeEngineAddress(), "MorpherMintingLimiter: Only Trade Engine is allowed to call this function");
        _;
    }

    modifier onlyAdministrator() {
        require(MorpherAccessControl(state.morpherAccessControlAddress()).hasRole(ADMINISTRATOR_ROLE, msg.sender), "MorpherMintingLimiter: Only Administrator can call this function");
        _;
    }

    constructor(address _stateAddress, uint256 _mintingLimitPerUser, uint256 _mintingLimitDaily, uint256 _timeLockingPeriodInSeconds) {
        state = MorpherState(_stateAddress);
        mintingLimitPerUser = _mintingLimitPerUser;
        mintingLimitDaily = _mintingLimitDaily;
        timeLockingPeriod = _timeLockingPeriodInSeconds;
    }

    function setTradeEngineAddress(address _tradeEngineAddress) public onlyAdministrator {
        emit TradeEngineAddressSet(_tradeEngineAddress);
        tradeEngineAddress = _tradeEngineAddress;
    }
    

    function setMintingLimitDaily(uint256 _newMintingLimit) public onlyAdministrator {
        emit MintingLimitUpdatedDaily(mintingLimitDaily, _newMintingLimit);
        mintingLimitDaily = _newMintingLimit;
    }
    function setMintingLimitPerUser(uint256 _newMintingLimit) public onlyAdministrator {
        emit MintingLimitUpdatedPerUser(mintingLimitDaily, _newMintingLimit);
        mintingLimitPerUser = _newMintingLimit;
    }

    function setTimeLockingPeriod(uint256 _newTimeLockingPeriodInSeconds) public onlyAdministrator {
        emit TimeLockPeriodUpdated(timeLockingPeriod, _newTimeLockingPeriodInSeconds);
        timeLockingPeriod = _newTimeLockingPeriodInSeconds;
    }

    function mint(address _user, uint256 _tokenAmount) public onlyTradeEngine {
        uint256 mintingDay = block.timestamp / 1 days;
        if((mintingLimitDaily == 0 || dailyMintedTokens[mintingDay] + (_tokenAmount) <= mintingLimitDaily) && (mintingLimitPerUser == 0 || _tokenAmount <= mintingLimitPerUser )) {
            MorpherToken(state.morpherTokenAddress()).mint(_user, _tokenAmount);
            dailyMintedTokens[mintingDay] = dailyMintedTokens[mintingDay] + (_tokenAmount);
        } else {
            escrowedTokens[_user] = escrowedTokens[_user] + (_tokenAmount);
            lockedUntil[_user] = block.timestamp + timeLockingPeriod;
            emit MintingEscrowed(_user, _tokenAmount);
        }
    }

    function delayedMint(address _user) public {
        require(lockedUntil[_user] <= block.timestamp, "MorpherMintingLimiter: Funds are still time locked");
        uint256 sendAmount = escrowedTokens[_user];
        escrowedTokens[_user] = 0;
        MorpherToken(state.morpherTokenAddress()).mint(_user, sendAmount);
        emit EscrowReleased(_user, sendAmount);
    }

    function adminApprovedMint(address _user, uint256 _tokenAmount) public onlyAdministrator {
        escrowedTokens[_user] = escrowedTokens[_user] - (_tokenAmount);
        MorpherToken(state.morpherTokenAddress()).mint(_user, _tokenAmount);
        emit EscrowReleased(_user, _tokenAmount);
    }

    function adminDisapproveMint(address _user, uint256 _tokenAmount) public onlyAdministrator {
        escrowedTokens[_user] = escrowedTokens[_user] - (_tokenAmount);
        emit MintingDenied(_user, _tokenAmount);
    }

    function resetDailyMintedTokens() public onlyAdministrator {
        dailyMintedTokens[block.timestamp / 1 days] = 0;
        emit DailyMintedTokensReset();
    }

    function getDailyMintedTokens() public view returns(uint256) {
        return dailyMintedTokens[block.timestamp / 1 days];
    }
}

//SPDX-License-Identifier: GPLv3
pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

contract MorpherAccessControl is AccessControlEnumerableUpgradeable {

    function initialize() public initializer {
        AccessControlEnumerableUpgradeable.__AccessControlEnumerable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/// @title Interface for WETH9
interface IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IPeripheryImmutableState {
    /// @return Returns the address of the Uniswap V3 factory
    function factory() external view returns (address);

    /// @return Returns the address of WETH9
    function WETH9() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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
library EnumerableSetUpgradeable {
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProofUpgradeable {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
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
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
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
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
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
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
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
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
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
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
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
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
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
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../../../security/PausableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20PausableUpgradeable is Initializable, ERC20Upgradeable, PausableUpgradeable {
    function __ERC20Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __ERC20Pausable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "../utils/structs/EnumerableSetUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerableUpgradeable, AccessControlUpgradeable {
    function __AccessControlEnumerable_init() internal onlyInitializing {
    }

    function __AccessControlEnumerable_init_unchained() internal onlyInitializing {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}
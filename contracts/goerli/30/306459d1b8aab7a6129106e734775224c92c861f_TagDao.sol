/**
 *Submitted for verification at Etherscan.io on 2022-11-06
*/

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: tag.sol


pragma solidity ^0.8.9;


// 投票トークンである、TagDaoTokenの保有情報を取得するために、TagDaoTokenTokenコントラクトの関数balanceOfを使用
interface TagDaoTokenInterface{
    function balanceOf(address owner) external view returns (uint256);
}

contract TagDao is Ownable {

    //投票トークンのコントラクト、投票可能かどうかの判定に用いる
    address public TagDaoTokenAddress;
    function setTagDaoTokenAddress(address _address) external onlyOwner{
        TagDaoTokenAddress = _address;
    }
    //投票NFTのホルダーかどうかの判断をする関数修飾子
    modifier checkHolder(){
        require(TagDaoTokenInterface(TagDaoTokenAddress).balanceOf(msg.sender) != 0);
        _;
    }

    //トレジャリー（daoメンバーに報酬を割り当てた後に残っている資金）の管理
    uint public treasuryAmount;

    //新しくtokenの登録を申請する場合、お金がかかるように設計。テスト用に、feeの価格は0.01ETHと低く設定。
    uint applicationFee = 10000000000000000; // 0.01ether = 10^16 wei
    uint allocateRate = 2; //applicationFeeのうち、何割を投票してくれた人に分配して、何割をコミュニティ運営のトレジャりーに残すかの割合。この場合、1/2が分配される。

    //登録トークンの雛形
    struct Token{
        uint id;
        string symbol;
        address contractAddress;
        string tag1;
        string tag2;
        string tag3;
    }

    uint tokenIdCounter = 0;

    //登録しているタグとトークンの配列
    string[] public registeredTags;
    Token[] public registeredTokens;

    //tag種類の追加 / 削除 / 修正に関する提案の雛形
    struct TagProposal{
        uint id;
        address proposer;
        string title;
        string description;
        string status;  //status：active → queued → excecuted か active → defeated
        uint startTimeStamp;
        uint expairTimeStamp;
        string[] appendTags;
        string[] deleteTags;
        uint[] forPolls;
        uint[] againstPolls;
    }

    //登録トークンの追加 / 削除 / 修正に関する雛形
    struct TokenProposal{
        uint id;
        address proposer;
        string description;
        string status;
        uint expairTimeStamp;
        Token appendToken;
        Token deleteToken;
        uint[] forPolls;
        uint[] againstPolls;
    }
    
     //提案を保管
    TagProposal[] public tagProposals;
    TokenProposal[] public tokenProposals;

    //提案のID
    uint tagProposalIdCounter = 0;
    uint tokenProposalIdCounter = 0;

    //投票者のID
    //0はmappingの関係で使わない
    uint voterIdCounter = 1;

    //投票者が行うトランザクションのガス代を最小にするために、strudtではなく、mappingをで保管
    //投票者のIDと、投票者のアドレスを紐づける
    mapping(uint => address)  voterIdToAddress; 
    //投票者のアドレスに対して、IDを紐付ける（修正余地あり）
    mapping(address => uint)  addressToVoterId; 
    //各投票者IDと投票で得た報酬を紐づける。報酬の単位はetherではなく、weiで計算
    mapping(uint => uint) voterIdToAllocatedFee;

    function tagList() external view returns(string[] memory){
        return registeredTags;
    }
    function tokenList() external view returns(Token[] memory){
        return registeredTokens;
    }


    //code sizeが上限ギリギリなので一旦優先度が低いtagProposal取得関数をコメントアウト
    // function tagProposal() external view returns(TagProposal[] memory){
    //     return tagProposals;
    // }

    // function tagProposal() external view returns(uint){
    //     return tagProposals.length;
    // }    
    
    function tokenProposal() external view returns(TokenProposal[] memory){
        return tokenProposals;
    }

    function checkDeposit(address _address) external view returns(uint){
        return voterIdToAllocatedFee[addressToVoterId[_address]];
    }

    //各投票の、賛成 / 反対の票数を取得する
    function tokenProposalVotersNum(uint _Id) public view returns(uint[2] memory){
        return [tokenProposals[_Id].forPolls.length, tokenProposals[_Id].againstPolls.length];
    }

    //タグに関する提案を受け付けて、storage保存する関数
    function proposeTagProposal(
        string memory _title,
        string memory _description,
        string[] memory _appendTags,
        string[] memory _deleteTags,
        uint _spanDays
    ) public checkHolder{
        TagProposal storage newTagProposal = tagProposals.push();
        newTagProposal.id = tagProposalIdCounter;
        newTagProposal.proposer = msg.sender;
        newTagProposal.title = _title;
        newTagProposal.description = _description;
        newTagProposal.status = "active";
        newTagProposal.startTimeStamp = block.timestamp;
        newTagProposal.expairTimeStamp = block.timestamp + _spanDays * 1 minutes;  //テストのために1days → 1miniutes
        newTagProposal.appendTags = _appendTags;
        newTagProposal.deleteTags = _deleteTags;

        tagProposalIdCounter++;
    }

    //tokenに関する提案を受け付けて、storageに保存する関数
    function proposeTokenProposal(
        string memory _description,
        string memory _appendSymbol,
        address  _appendContractAddress,
        string[3] memory _appendTags,
        string memory _deleteSymbol,
        address  _deleteContractAddress,
        string[3] memory _deleteTags,
        uint _spanDays
    ) public payable{
        //初申請のコントラクトアドレスには、申請料金を徴収する。
        bool isFirstTime = true;
        if (registeredTokens.length != 0){
            for (uint i = 0; i < registeredTokens.length; i++){
                if (registeredTokens[i].contractAddress == _appendContractAddress){
                    isFirstTime = false;
                }
            }
        }
        
        if (isFirstTime){
            require(msg.value == applicationFee);
            treasuryAmount += applicationFee;
        }
        //保存
        TokenProposal storage newTokenProposal = tokenProposals.push();
        newTokenProposal.id = tokenProposalIdCounter;
        newTokenProposal.proposer = msg.sender;
        newTokenProposal.description = _description;
        newTokenProposal.status = "active";
        //newTokenProposal.startTimeStamp = block.timestamp;
        newTokenProposal.expairTimeStamp = block.timestamp + _spanDays * 1 minutes;
        newTokenProposal.appendToken = Token(0,_appendSymbol, _appendContractAddress,  _appendTags[0], _appendTags[1], _appendTags[2]);
        newTokenProposal.deleteToken = Token(0, _deleteSymbol, _deleteContractAddress,  _deleteTags[0], _deleteTags[1], _deleteTags[2]);
        
        tokenProposalIdCounter++;
    }

    //Tagに関するプロポーサルIDと、賛成 / 反対のpollを入力すると、そのプロポーサルのfor / againstPollsにvoterIDが追加される
    function voteTagProposal(uint _id, bool _poll) public checkHolder{
        require(tagProposals[_id].expairTimeStamp >= block.timestamp);
        uint voterId = addressToVoterId[msg.sender];
        //投票したことがあるかどうかをチェックするためのbool
        uint voted = 0;
        if (voterId == 0){
            addressToVoterId[msg.sender] = voterIdCounter;
            voterIdToAddress[voterIdCounter] = msg.sender;
            voterIdCounter++;
            voterId = 1;
        //投票者IDが与えられている場合
        }else{
            uint[] memory forList = tagProposals[_id].forPolls;
            if (forList.length > 0){
                for (uint i = 0; i < forList.length; i++){
                    if (forList[i] == voterId){
                        voted = 1;
                    }
                }
            }
            uint[] memory againstList = tagProposals[_id].againstPolls;
            if (againstList.length > 0){
                for (uint i = 0; i < againstList.length; i++){
                    if (againstList[i] == voterId){
                        voted = 1;
                    }
                }
            }
        }
        require(voted == 0);
        if (_poll) { 
            tagProposals[_id].forPolls.push(voterId);
        }else{
            tagProposals[_id].againstPolls.push(voterId);
        } 
    }

    //tokenに関するプロポーサルIDと、賛成 / 反対のpollを入力すると、そのプロポーサルのfor / againstPollsにvoterIDが追加される
    function voteTokenProposal(uint _id, bool _poll) public checkHolder{
        require(tokenProposals[_id].expairTimeStamp >= block.timestamp);
        uint voterId = addressToVoterId[msg.sender];
        //投票したことがあるかどうかをチェックするためのbool
        uint voted = 0;
        if (voterId == 0){
            voterId = voterIdCounter;
            addressToVoterId[msg.sender] = voterIdCounter;
            voterIdToAddress[voterIdCounter] = msg.sender;
            voterIdCounter++;
            voterId = 1;
        }else{
            uint[] memory forList = tokenProposals[_id].forPolls;
            if (forList.length > 0){
                for (uint i = 0; i < forList.length; i++){
                    if (forList[i] == voterId){
                        voted = 1;
                    }
                }
            }
            uint[] memory againstList = tokenProposals[_id].againstPolls;
            if (againstList.length > 0){
                for (uint i = 0; i < againstList.length; i++){
                    if (againstList[i] == voterId){
                        voted = 1;
                    }
                }
            }
        }
        require(voted == 0);
        
        if (_poll) { 
            tokenProposals[_id].forPolls.push(voterId);
        }else{
            tokenProposals[_id].againstPolls.push(voterId);
        }
        
    }

    //一定期間が経って、プロポーサルの票数を確認して次のステージへと移す　active→queued or defeated
    //この作業は誰がやっても良いのでexternal
    function checkExpairTagProposal(uint _id) external {
        require(tagProposals[_id].expairTimeStamp <= block.timestamp);
        require(keccak256(abi.encodePacked(tagProposals[_id].status)) == keccak256(abi.encodePacked("active")));
        if (tagProposals[_id].forPolls.length >= tagProposals[_id].againstPolls.length){
            tagProposals[_id].status = "queued";
        }else if (tagProposals[_id].forPolls.length < tagProposals[_id].againstPolls.length){
            tagProposals[_id].status = "defeated";
        }
    }

    function checkExpairTokenProposal(uint _id) external {
        require(tokenProposals[_id].expairTimeStamp <= block.timestamp);
        require(keccak256(abi.encodePacked(tokenProposals[_id].status)) == keccak256(abi.encodePacked("active")));
        if (tokenProposals[_id].forPolls.length >= tokenProposals[_id].againstPolls.length){
            tokenProposals[_id].status = "queued";
        }else if (tokenProposals[_id].forPolls.length < tokenProposals[_id].againstPolls.length){
            tokenProposals[_id].status = "defeated";
        }  
    }
    //queuedに入っているproposalを実行に移す
    //この手順は、adminによってノミなされる（精査の余地を与える）
    function executeTagProposal(uint _id) external onlyOwner{
        require(keccak256(abi.encodePacked(tagProposals[_id].status)) == keccak256(abi.encodePacked("queued")));
        string[] memory appendTags = tagProposals[_id].appendTags;
        string[] memory deleteTags = tagProposals[_id].deleteTags;
        if (appendTags.length > 0){
            for (uint i = 0; i < appendTags.length; i++){
                registeredTags.push(appendTags[i]);
            }
        }
        if (deleteTags.length > 0){
            for (uint j = 0; j < deleteTags.length; j++){
                if (registeredTags.length != 0){
                    for (uint k = 0; k < registeredTags.length; k++){
                        if (keccak256(abi.encodePacked(registeredTags[k])) == keccak256(abi.encodePacked(deleteTags[j]))){
                            delete registeredTags[k];
                        }
                    }
                }
            }
        }
        tagProposals[_id].status = "executed";
    }

    //キューに入っているtokenの申請/ 変更/ 削除のproposalを実行して、tokenTagRelationsに反映させる。
    //Nounsを模倣して、adminが最終的な精査をできるように設計。（=adminのみがこの作業を行えるようにした）
    function executeTokenProposal(uint _id) external onlyOwner{
        require(keccak256(abi.encodePacked(tokenProposals[_id].status)) == keccak256(abi.encodePacked("queued")));
        Token memory appendToken = tokenProposals[_id].appendToken;
        Token memory deleteToken = tokenProposals[_id].deleteToken;
        if (appendToken.contractAddress != address(0)){
            appendToken.id = tokenIdCounter;
            registeredTokens.push(appendToken);
            tokenIdCounter++;
        }
        if (deleteToken.contractAddress != address(0)){
            if (registeredTokens.length != 0){
                for (uint i = 0; i < registeredTokens.length; i++){
                    if (registeredTokens[i].contractAddress == deleteToken.contractAddress){
                        delete registeredTokens[i];
                    }
                }
            }
        }
        tokenProposals[_id].status = "executed";
        if (tokenProposals[_id].deleteToken.contractAddress == address(0)){
            if (tokenProposals[_id].forPolls.length + tokenProposals[_id].againstPolls.length != 0){
                allocateFee(_id);
            } 
        }
    }
    //tokenの初申請に対する投票の報酬分配。　最終的な結果（賛成 / 反対）と同じ投票をしていた人で分配するように設計→美人投票的になるが、tag付の場合はこれが有効。
    function allocateFee(uint _id) private{
        uint[] memory winList;
        if (tokenProposals[_id].forPolls.length >= tokenProposals[_id].againstPolls.length){
            winList = tokenProposals[_id].forPolls;
        }else{
            winList = tokenProposals[_id].againstPolls;
        }
        //早く投票した人が多くもらい、遅い人が少なくもらうように設定
        uint allocateFeeSum = applicationFee / allocateRate;
        uint remainder = allocateFeeSum % winList.length;
        uint aveAllocation = (allocateFeeSum - remainder ) / winList.length;
        uint tilt = (2 * aveAllocation - (2 * aveAllocation) % winList.length) / winList.length;
        for (uint i = 0; i < winList.length; i++){
            voterIdToAllocatedFee[winList[i]] += 2 * aveAllocation - tilt * i;
        }
        treasuryAmount -= allocateFeeSum - remainder;
    } 

       //DAOの参加者が、投票して得た報酬を引き出す関数
    function withdrawAllocateFee() public {
        require(voterIdToAllocatedFee[addressToVoterId[msg.sender]] != 0);
        payable(msg.sender).transfer(voterIdToAllocatedFee[addressToVoterId[msg.sender]]);
    }

    //オーナーがトレジャリーを引き出す関数
    function withdrawTreasury(uint _withdrawAmount) external onlyOwner{
        require(treasuryAmount >= _withdrawAmount);
        payable(msg.sender).transfer(_withdrawAmount);
    }
    
}
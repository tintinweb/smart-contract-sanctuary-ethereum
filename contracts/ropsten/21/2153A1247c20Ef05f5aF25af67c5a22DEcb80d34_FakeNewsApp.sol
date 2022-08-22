//SPDX-License-Identifier: GPL-3.0
pragma solidity  ^ 0.8.0 ;
contract FakeNewsApp{
    struct article{

        //public
        uint256 id;
        string content_URI;
        uint256 time_created;
        address[]participants;
        ArticleStatus status;

        //private
        bool  verdict;
        uint256 _for;
        uint256 against;
        uint256 forStake;
        uint256 againstStake;
   

    }
    struct DisplayArticle{
         uint256 id;
        string content_URI;
        uint256 time_created;
        uint256 totalParticipants;
        ArticleStatus status;

    }
    struct participant{
        address  id;
        bool vote;
        bool hasVoted;
        uint256 staked;

    }
     enum ArticleStatus{
         CreationCompleted,
         ResultCalculated,
         DistributionCompleted
     }
   mapping (uint=>article) private articleList;
   mapping(uint256=>mapping(address=>participant)) private Participants;

   mapping (uint=>DisplayArticle) public DisplayArticleList;
   uint256 [] public totalArticles;

   //mapping(address=>uint256) public voteStore;
   

    //From openZepplin
       function tryDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            if (b == 0) return (0);
            return ( a / b);
        }
    }

    function initializeArticle(uint256 _id,string memory _uri) public{
        article  memory newArticle; 
        DisplayArticle memory newDisplayArticle ;     

        newArticle.id = _id;
        newArticle.content_URI = _uri;
        newArticle.time_created = block.timestamp;
        newArticle.status =ArticleStatus.CreationCompleted; 

        newDisplayArticle.id = _id;
        newDisplayArticle.content_URI = _uri;
        newDisplayArticle.time_created = block.timestamp;
        newDisplayArticle.status =ArticleStatus.CreationCompleted; 

        articleList[_id] = newArticle;
        DisplayArticleList[_id] =  newDisplayArticle;
        totalArticles.push(_id);

    }
    function participate(uint256 _id)public{
        participant memory newPart = participant(msg.sender,false,false,0);
         Participants[_id][msg.sender] = newPart;
             DisplayArticleList[_id].totalParticipants++;
    }
    function voteFor(uint256 _id,uint256 stake) payable public{
       require(msg.value==stake);
       require( Participants[_id][msg.sender].hasVoted == false,"You have already voted");
       require(articleList[_id].status == ArticleStatus.CreationCompleted,"Sorry Session has ended");
       Participants[_id][msg.sender].vote = true;
       Participants[_id][msg.sender].staked +=stake; 
       Participants[_id][msg.sender].hasVoted = true ; 

       articleList[_id].participants.push(msg.sender);
       articleList[_id]._for++ ;
       articleList[_id].forStake += stake;

      // DisplayArticleList[_id].participants.push(msg.sender);
      

    }
    function voteAgainst(uint256 _id,uint256 stake) payable public{
       require(msg.value==stake);
       require( Participants[_id][msg.sender].hasVoted == false,"You have already voted");
       require(articleList[_id].status == ArticleStatus.CreationCompleted,"Sorry Session has ended");

       Participants[_id][msg.sender].vote = false;
       Participants[_id][msg.sender].staked +=stake; 
       Participants[_id][msg.sender].hasVoted = true ;

       articleList[_id].participants.push(msg.sender);
       articleList[_id].against++ ;
       articleList[_id].againstStake += stake;

    }

    function calculateResult(uint256 id)external {
       require(articleList[id].status != ArticleStatus.ResultCalculated,"Result already Calculated");
        require(articleList[id].status != ArticleStatus.DistributionCompleted,"Stakes already distributed");
        if(articleList[id]._for>=articleList[id].against){
            articleList[id].verdict = true;
        }
        else{
            articleList[id].verdict = false;
        }
        articleList[id].status = ArticleStatus.ResultCalculated;
        DisplayArticleList[id].status = ArticleStatus.ResultCalculated;


    }
    function distribute(uint256 _id)external payable{
        require(articleList[_id].status == ArticleStatus.ResultCalculated,"Sorry Result not calculated");

        uint256 total = articleList[_id]._for + articleList[_id].against;
        bool _verdict = articleList[_id].verdict;
        
        if(_verdict == true) {
        for(uint i=0;i<total;i++){
       
            if( Participants[_id][articleList[_id].participants[i]].vote == true){
                 uint256 stake =  Participants[_id][articleList[_id].participants[i]].staked;
                 payable( articleList[_id].participants[i]).transfer( Participants[_id][articleList[_id].participants[i]].staked+tryDiv(stake*articleList[_id].againstStake, articleList[_id].forStake));
            }
        }
        }
        else{
            for(uint i=0;i<total;i++){
              if( Participants[_id][articleList[_id].participants[i]].vote == false){
                uint256 stake =  Participants[_id][articleList[_id].participants[i]].staked;
                 payable( articleList[_id].participants[i]).transfer( Participants[_id][articleList[_id].participants[i]].staked+tryDiv(stake*articleList[_id].forStake, articleList[_id].againstStake));
                // Participants[_id][articleList[_id].participants[i]].staked=0;
            }
        
          }
       }
        articleList[_id].status = ArticleStatus.DistributionCompleted;

    }

//VIEW FUNCTIONS
function getTime(uint256 id)external view returns(uint256){
    return articleList[id].time_created;
}
    function getArticles() external view returns (uint256 [] memory ){
        return totalArticles;
    }
     function getParticipants (uint256 id) external  view  returns ( address [] memory ) {
        return articleList[id].participants;
    }
    function getParticipantsStake(uint256 id,address _add) external view returns(uint256){
        return(Participants[id][_add].staked);
    }
        function getParticipantsVote (uint256 id,address _add) external view returns(bool){
        require(articleList[id].status==ArticleStatus.ResultCalculated,"Session not Completed");
        return (Participants[id][_add].vote);
    }
        function getVerdict(uint256 id) external view returns (bool){
             require( articleList[id].status == ArticleStatus.ResultCalculated,"Session not Completed");
             return(articleList[id].verdict);
    }
        function getCurrentStatus(uint256 id) external view returns (uint8 stat){
           if(articleList[id].status == ArticleStatus.CreationCompleted){
               stat =0;
               return stat;
           }
           if(articleList[id].status == ArticleStatus.ResultCalculated){
               stat = 1;
               return stat;
           }
           else{
               stat = 2;
               return stat;
           }
    }
       function getContractBalance() public view returns (uint256) { //view amount of ETH the contract contains
        return address(this).balance;
    }

}
pragma solidity ^0.8.7;
import "./ownable.sol";


/**
 * @title CryptoWorldCup
 * @dev ContractDescription
 * @custom:dev-run-script ./scripts/deploy_with_web3.ts
 */

contract CryptoWorldCup is Ownable {

    //event NewSweetstake(uint sweetstakeId, string _team1, string _team2, uint _score1 uint _score2);
    address payable public ceoAddress;
    uint public limitDate;

    constructor() public{
        ceoAddress=payable(msg.sender);
        limitDate = 1668988800; //21-12-2022
    }

    struct Sweetstake {
        string team1;
        string team2;
        uint8 score1;
        uint8 score2;
    }

    Sweetstake[] public sweetstakes;
    mapping (uint => address) public sweetstakeToOwner;
    mapping (address => uint) ownerSweetstakeCount;
    mapping (address => uint[]) ownerToSweetstake;
    mapping (address => bool) public addressWinner;
    mapping (address => bool) public awardClaimed;

    uint counterWinners = 0;

    function _createSweetstake( string memory _team1, string memory _team2, uint8 _score1, uint8 _score2) external payable {
        // IMPORTANT: IF YOU ARE GOING TO CREATE A SWEETSTAKE IN BSCSCAN, THE NOMENCLATURE OF THE TEAMS IS AS FOLLOWS:
        // YOU HAVE TO ENTER THE NOMENCLATURE IDENTICALY
        // Germany: DE, Saudi Arabia: SA, Argentina: AR, Belgium: BE, Brazil: BR, Cameroon: CM, Canada: CA
        // South Korea: KR, Costa Rica: CR, Croatia: HR, Denmark: DK, Ecuador: EC, EEUU: US, Spain: ES
        // France: FR, Wales: GAL, Ghana: GH, Netherlands: NL, England: ING, Iran: IR, Japan: JP,
        // Morocco: MA, Mexico: MX, Poland: PL, Portugal: PT, Qatar: QA, Senegal: SN, Serbia: RS,
        // Switzerland: CH, Tunisia: TN, Uruguay: UY
        
        require(block.timestamp < limitDate);
        require(msg.value == 1 ether);
        require( ownerSweetstakeCount[msg.sender]<=4); //one addres can't have more than 5 Sweetstakes
        bool validSweetstake = true;
        for (uint i = 0; i<ownerToSweetstake[msg.sender].length; i++){
            if((compareStrings(sweetstakes[ownerToSweetstake[msg.sender][i]].team1, _team1) && compareStrings(sweetstakes[ownerToSweetstake[msg.sender][i]].team2, _team2) && sweetstakes[ownerToSweetstake[msg.sender][i]].score1 == _score1 && sweetstakes[ownerToSweetstake[msg.sender][i]].score2 == _score2) || (compareStrings(sweetstakes[ownerToSweetstake[msg.sender][i]].team2, _team1) && compareStrings(sweetstakes[ownerToSweetstake[msg.sender][i]].team1, _team2) && sweetstakes[ownerToSweetstake[msg.sender][i]].score1 == _score2 && sweetstakes[ownerToSweetstake[msg.sender][i]].score2 == _score1)){
                validSweetstake = false;
            }
        }
        require(validSweetstake);
        sweetstakes.push(Sweetstake(_team1, _team2, _score1, _score2));
        uint id = sweetstakes.length-1;
        if(ownerSweetstakeCount[msg.sender] == 0){
            awardClaimed[msg.sender] = false;
        }
        sweetstakeToOwner[id] = msg.sender;
        ownerSweetstakeCount[msg.sender]++;
        ownerToSweetstake[msg.sender].push(id);

        uint256 fee=devFee(msg.value);
        ceoAddress.transfer(fee);

    }

    //Return NFTs in a wallet
    function getSweetstakeByOwner(address _owner) external view returns (uint[] memory) {
        return ownerToSweetstake[_owner];
    }

    // Funtion to public the final result and assign winners
    /*function setFinalResult(string memory _team1, string memory _team2, uint _score1, uint _score2) public onlyOwner{
        for (uint i = 0; i<sweetstakes.length; i++){
            if((compareStrings(sweetstakes[i].team1, _team1) && compareStrings(sweetstakes[i].team2, _team2) && sweetstakes[i].score1 == _score1 && sweetstakes[i].score2 == _score2) || (compareStrings(sweetstakes[i].team2, _team1) && compareStrings(sweetstakes[i].team1, _team2) && sweetstakes[i].score1 == _score2 && sweetstakes[i].score2 == _score1)){
                counterWinners++;
                addressWinner[sweetstakeToOwner[i]] = true;
            }
            
        }
    }*/

    function getCounterWinners(string memory _team1, string memory _team2, uint _score1, uint _score2) view public onlyOwner returns(uint256){
        uint256 counter = 0;
        for (uint i = 0; i<sweetstakes.length; i++){
            if((compareStrings(sweetstakes[i].team1, _team1) && compareStrings(sweetstakes[i].team2, _team2) && sweetstakes[i].score1 == _score1 && sweetstakes[i].score2 == _score2) || (compareStrings(sweetstakes[i].team2, _team1) && compareStrings(sweetstakes[i].team1, _team2) && sweetstakes[i].score1 == _score2 && sweetstakes[i].score2 == _score1)){
                counter++;
            }
                       
        }
        return counter;
    }

    function getWinnersArray(string memory _team1, string memory _team2, uint _score1, uint _score2, uint256 _counter) view public onlyOwner returns (address[] memory){
        address[] memory winnersArray = new address[](_counter);
        uint256 j =0;
        for (uint i = 0; i<sweetstakes.length; i++){
            if((compareStrings(sweetstakes[i].team1, _team1) && compareStrings(sweetstakes[i].team2, _team2) && sweetstakes[i].score1 == _score1 && sweetstakes[i].score2 == _score2) || (compareStrings(sweetstakes[i].team2, _team1) && compareStrings(sweetstakes[i].team1, _team2) && sweetstakes[i].score1 == _score2 && sweetstakes[i].score2 == _score1)){
                winnersArray[j]=sweetstakeToOwner[i];
                j++;
            }
            
        }
        return winnersArray;
    }

    function setFinalWinners(address[] memory addressArray) public onlyOwner{
        for(uint i=0;i<addressArray.length;i++){
            addressWinner[addressArray[i]] = true;
        }
        counterWinners=addressArray.length;
    }


    function claimAward() public {
        require(addressWinner[msg.sender]==true);
        require(awardClaimed[msg.sender]==false);
        payable(msg.sender).transfer((address(this).balance)/counterWinners);
        awardClaimed[msg.sender]=true;
    }



    function devFee(uint256 amount) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,5),100);
    }

    function compareStrings(string memory a, string memory b) public view returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }




}


library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
import "./Ownable.sol";
import "./dogMarketplace.sol";

pragma solidity ^0.5.0;

contract DogCore is Ownable, DogMarketPlace {

  uint256 public constant CREATION_LIMIT_GEN0 = 1000000000;

  uint256 public gen0Counter;

  constructor() public {
    _createDog(0, 0, 0, uint256(-1), address(0));
  }


  function Breeding(uint256 _fatherId, uint256 _motherId) public {
      require(_owns(msg.sender, _fatherId), "The user doesn't own the token");
      require(_owns(msg.sender, _motherId), "The user doesn't own the token");

      require(_motherId != _fatherId, "reproduction by self not possible");

      ( uint256 fathergenes,,,,uint256 fatherGeneration ) = getDog(_fatherId);

      ( uint256 mothergenes,,,,uint256 motherGeneration ) = getDog(_motherId);

      uint256 geneKid;
      uint256 [11] memory geneArray;
      uint256 index = 10;
      uint8 random = uint8(now % 255);
      uint256 i = 1;
      uint256 k = 1;
      
      for(i = 1; i <= 1024; i=i*2){
          k=i;
          if(i == 256){
              k=128;
          }
          if(i == 512){
              k=64;
          }
           if(i == 1024){
              k=32;
          }
          if(random & k != 0){
              geneArray[index] = uint8(mothergenes % 10);
          } else {
              geneArray[index] = uint8(fathergenes % 10);
          }
          mothergenes /= 10;
          fathergenes /= 10;
        index -= 1;
      }

      for (i = 0 ; i < 11; i++ ){
        geneKid += geneArray[i];
        if(i != 10){
            geneKid *= 10;
        }
      }

      uint256 kidGen = 0;
      if (fatherGeneration < motherGeneration){
        kidGen = motherGeneration + 1;
      } else if (fatherGeneration > motherGeneration){
        kidGen = fatherGeneration + 1;
      } else{
        kidGen = motherGeneration + 1;
      }

      _createDog(_motherId, _fatherId, kidGen, geneKid, msg.sender);
  }


  function createDogGen0(uint256 _geneSequence) public {
    require(gen0Counter < CREATION_LIMIT_GEN0);

    gen0Counter++;

    uint256 tokenId = _createDog(0, 0, 0, _geneSequence, msg.sender);
    
  }

  function getDog(uint256 _id)
    public
    view
    returns (
    uint256 geneSequence,
    uint256 birthTime,
    uint256 motherId,
    uint256 fatherId,
    uint256 generation
  ) {
    Dog storage Dog = dogs[_id];

    require(Dog.birthTime > 0, "the Dog doesn't exist");

    birthTime = uint256(Dog.birthTime);
    motherId = uint256(Dog.motherId);
    fatherId = uint256(Dog.fatherId);
    generation = uint256(Dog.generation);
    geneSequence = Dog.geneSequence;
  }
}
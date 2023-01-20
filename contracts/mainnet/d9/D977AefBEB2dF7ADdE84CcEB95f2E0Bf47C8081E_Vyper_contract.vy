# @version ^0.3.7

"""
@title NPC View Optimizer
@author npcers.eth
@notice On-chain aggregator for NPC 🥩 view functions, used for frontend.
@dev Saves frontend multicall load time.  Not for on-chain use due to gas costs

         :=+******++=-:                 
      -+*+======------=+++=:            
     %+========------------=++=.        
    %+=======------------------++:      
   *+=======--------------------:++     
  =*=======------------------------*.   
 .%========-------------------------*.  
 %+=======-------------------------:-%  
+*========--------------------------:%  
%=========--------------------------:%. 
%=========--------------------+**=--:++ 
%+========-----=*%%%=--------%%%%%+-::*:
:%========-----+%%%%%=-------=%%%%%-::+=
 -%======-------+%%%%=----=*=--+**=-::%:
  :%+====---------==----===%%=------::% 
    %+===-------------======%%=------:=+
    .%===------------=======+%%------::%
     %+==-----------=========+%%-------+
     %===------------*%%%%%%%%%%%-----%.
     %====-----------============----%: 
     *+==%+----------+%%%%%%%%%%%--=*.  
     -%==+%=---------=+=========--*=    
      +===+%+--------------------*-     
       =====*%=------------------%      
       .======*%*=------------=*+.      
         -======+*%*+--------*+         
          .-========+***+++=-.          
             .-=======:           

"""



interface NPC:
    def ownerOf(id: uint256) -> address: view
    def totalSupply() -> uint256: view

nft: public(NPC)
MAX_SUPPLY: constant(uint256) = 6000

@external
def __init__(addr: address):
	self.nft = NPC(addr)

@external
@view
def tokenOfOwnerByIndex(owner: address, index: uint256) -> uint256:
	"""
	@notice Replaces tokenOfOwnerByIndex, correcting error in NPC NFT
	@dev Not recommended for on-chain use due to gas costs.
	@param owner User to query
	@param index Offset for user
	@return Actual NFT ID
	"""
	counter: uint256 = 0
	ret_val: uint256 = 0
	for i in range(MAX_SUPPLY):
		if owner == self.nft.ownerOf(i):
			if counter == index:
				ret_val = i
				break
			else:
				counter += 1	

	return ret_val


@external
@view
def tokensForOwner(owner: address) -> DynArray[uint256, 6000]:
    """
    @notice Retrieve all owned tokens for address
    @param owner User to query
    @return All tokens owned by user
    @dev Gas prohibitive, not recommended
    """
    ret_array: DynArray[uint256, 6000] = []
    max_supply: uint256 = self.nft.totalSupply()

    for i in range(MAX_SUPPLY):
        if i >= max_supply:
            break

        if owner == self.nft.ownerOf(i):
            ret_array.append(i) 

    return ret_array
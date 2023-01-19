# @version ^0.3.7
from vyper.interfaces import ERC721

nft: public(ERC721)
MAX_SUPPLY: constant(uint256) = 6000

@external
def __init__(addr: address):
	self.nft = ERC721(addr)

@external
@view
def tokenOfOwnerByIndex(owner: address, index: uint256) -> uint256:
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
    ret_array: DynArray[uint256, 6000] = []
    for i in range(MAX_SUPPLY):
        if owner == self.nft.ownerOf(i):
            ret_array.append(i) 
    return ret_array
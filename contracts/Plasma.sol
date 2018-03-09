pragma solidity ^0.4.4;


contract Plasma {
  function Plasma() {
    // constructor
  }

  bytes constant PersonalMessagePrefixBytes = "\x19Ethereum Signed Message:\n96";
  uint32 constant blockHeaderLength = 161;

  uint256 public lastBlockNumber;
  mapping(uint256 => BlockHeader) public blockHeaders;

  event HeaderSubmitted(uint256 blockNumber);

  struct BlockHeader {
  	uint256 submitTime;
  	uint32 blockNumber;  	
  	uint8 v;
  	bytes32 previousBlockHash;
  	bytes32 merkleRootHash;
  	bytes32 r;
  	bytes32 s;
  }

  function submitBlock(bytes32 blockHeader) external returns (bool success) {
  	require(blockHeader.length == blockHeaderLength);

  	bytes32 _blockNumber;
  	bytes32 _previousBlockHash;
  	bytes32 _merkleRootHash;
  	bytes32 _r;
  	bytes32 _s;
  	bytes1 _v;
  	assembly {
  		let data := add(blockHeader, 0x20)
  		_blockNumber := mload(data)
  		_previousBlockHash := mload(add(data, 32))
  		_merkleRootHash := mload(add(data, 64))
  		_r := mload(add(data, 96))
  		_s := mload(add(data, 128))
  		_v := mload(add(data, 1260))
  	}

  	require(uint256(_blockNumber) == lastBlockNumber + 1);
  	//Check signature
  	bytes32 blockHash = keccak256(PersonalMessagePrefixBytes,
  		_blockNumber, _previousBlockHash, _merkleRootHash);
  	address signer = ecrecover(blockHash, uint8(_v), _r, _s);
  	require(msg.sender == signer);

  	BlockHeader memory newHeader = BlockHeader({
  		submitTime = now,
  		blockNumber = _blockNumber,
  		v = _v,
  		previousBlockHash = _previousBlockHash,
  		merkleRootHash = _merkleRootHash,
  		r = _r,
  		s = _s
  	});

  	//Add block to list of block headers
  	blockHeaders[uint256(_blockNumber)] = newHeader;

  	//Increment the block number by 1
  	lastBlockNumber += 1;

  	HeaderSubmitted(uint256(_blockNumber));
  	return true;
  }
}

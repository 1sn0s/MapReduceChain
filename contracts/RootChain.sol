pragma solidity ^0.5.1;

import "./MerkleProof.sol";
import "./ECDSA.sol";
import "./BytesLib.sol";

contract Plasma {
  function Plasma() {
    // constructor
  }

  event DepositCreated (
	  address indexed owner,
	  uint amount,
	  uint blockNumber
  );

  event BlockSubmitted (
	  uint blockNumber,
	  bytes32 blockRoot
  );

  event ExitStarted (
	  address indexed owner,
	  uint blockNumber,
	  uint txIndex,
	  uint outputIndex,
	  uint amount
  );



	// Structures

  struct PlasmaBlock {
	  bytes32 root;
	  uint timestamp;
  }

  struct PlasmaExit {
	  address owner;
	  uint amount;
	  bool isActive;
	  bool isBlocked;
  }

  // Public Variables

  uint constant public CHALLENGE_PERIOD = 100;
  uint constant public EXIT_BOND = 100;

  // Variables
  PriorityQueue exitQueue;
  uint public currentPlasmaBlockNumber;
  address public operator;

  // Mapping from blockNumber to plasma blocks
  mapping ( uint => PlasmaBlock) public plasmaBlocks;
  // Mapping from exitIDs to 
  mapping ( uint => PlasmaExit) public plasmaExits;

  /**
	* @title Make a deposit to the plasma root
	* @dev Payable function that accepts deposits for root
	* @return block number of the deposit block
    */
  function deposit() public payable returns (uint blockNumber) {
	  bytes32 rootHash = keccak256(abi.encodePacked(msg.sender, msg.value));
	  plasmaBlocks[currentPlasmaBlockNumber] = PlasmaBlock(rootHash, block.timestamp);

	  emit DepositCreated(msg.sender, msg.value, currentPlasmaBlockNumber);
	  currentPlasmaBlockNumber = currentPlasmaBlockNumber.add(1);
  }

  /**
  	* @title Submit a block to the plasma root
	* @dev submit method for child chains to commit blocks
	* @param _blockRoot The root of the childs block to submit
	*/
  function submitBlock(bytes32 _blockRoot) public {
	  plasmaBlock[currentPlasmaBlockNumber] = PlasmaBlock(_blockRoot, block.timestamp);

	  emit BlockSubmitted(currentPlasmaBlockNumber, _blockRoot);
	  currentPlasmaBlockNumber = currentPlasmaBlockNumber.add(1);
  }

  /**
  	* @title Exit from the child chain
	* @dev Allows any user to withdraw funds from the contract by pointing to a transaction output
	*/
  function startExit(
	  uint _txoBlockNumber,
	  uint _txoTxIndex,
	  uint _txoOutputIndex,
	  bytes _encodedTx,
	  bytes _txInclusionProof,
	  bytes _txSignatures,
	  bytes _txConfirmationSignatures
  ) public payable returns (bool sucess)
  {
	  bytes32 rootHash = plasmaBlock[_txoBlockNumber].root;
	  require(MerkleProof.verify(_txInclusionProof, rootHash, _encodedTx) == true,
	   "Invalid transaction merkle proof");
	  
	  var txHash = keccak256(_encodedTx);
	  var confHash = keccak256(txHash);
	  bytes inputSig_1 = BytesLib.slice(_txSignatures, 0, 65);
	  bytes inputSig_2 = BytesLib.slice(_txSignatures, 65, 65);
	  bytes confirmSig_1 = BytesLib.slice(_txConfirmationSignatures, 0, 65);
	  bytes confirmSig_2 = BytesLib.slice(_txConfirmationSignatures, 0, 65);
	  
	  require(ECDSA.recover(txHash, inputSig_1) == ECDSA.recover(confHash, confirmSig_1),
	   "First signatures don't match");
	  require(ECDSA.recover(txHash, inputSig_2) == ECDSA.recover(confHash, confirmSig_2),
	   "First signatures don't match");

	  emit ExitStarted(msg.sender, _txoBlockNumber, _txoTxIndex, _txoOutputIndex, )
  }

  function challengeExit(

  ){}

  function processExits() public returns (uint processed) {

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
  		_v := mload(add(data, 160))
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

  function deposit() payable external returns (bool success) {
  	
  }
}

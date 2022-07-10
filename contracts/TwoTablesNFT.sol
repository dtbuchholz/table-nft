// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

/**
 * @dev A simple NFT using Tableland to host metadata in a two table setup
 */
contract TwoTablesNFT is ERC721 {
	// A URI used to reference off-chain metadata.
	string public baseURIString;
	// The name of the main metadata table in Tableland
	// Schema: id int, name text, description text, image text
	string public mainTable;
	// The name of the attributes table in Tableland
	// Schema: id int, trait_type text, value text
	string public attributesTable;
	// A token counter, to track NFT tokenIds.
	uint256 private _tokenIds;

	/**
	 * @dev Initialize TableNFT
	 * @param baseURI Set the contract's base URI to the Tableland gateway.
	 * @param _mainTable The name of the 'main' table for NFT metadata
	 * @param _attributesTable The corresponding 'attributes' table
	 */
	constructor(
		string memory baseURI,
		string memory _mainTable,
		string memory _attributesTable
	) ERC721('TwoTablesNFT', 'TTNFT') {
		// Initialize with token counter at zero.
		_tokenIds = 0;
		// Set the base URI
		baseURIString = baseURI;
		// Set the table names
		mainTable = _mainTable;
		attributesTable = _attributesTable;
	}

	/**
	 *  @dev Must override the default implementation, which returns an empty string.
	 */
	function _baseURI() internal view override returns (string memory) {
		return baseURIString;
	}

	/**
	 *  @dev Must override the default implementation, which simply appends a tokenId to _baseURI.
	 *  @param tokenId The id of the NFT token that is being requested.
	 */
	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
		require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
		string memory baseURI = _baseURI();

		if (bytes(baseURI).length == 0) {
			return '';
		}

		/**
            A SQL query to JOIN two tables to compose the metadata accross a 'main' and 'attributes' table

            SELECT json_object('id',table_nft_main_80001_35.id,'name',name,'description',description,'attributes',
                json_object('trait_type',trait_type,'value',value))
            FROM table_nft_main_80001_35 JOIN table_nft_attributes_80001_36
            WHERE table_nft_main_80001_35.id = table_nft_attributes_80001_36.id and table_nft_main_80001_35.id=
         */
		string memory query = string(
			abi.encodePacked(
				'SELECT%20',
				'json_object%28%27id%27%2C',
				mainTable,
				'%2Eid%2C%27name%27%2Cname%2C%27description%27%2Cdescription%2C%27attributes%27%2Cjson_object%28%27trait_type%27%2Ctrait_type%2C%27value%27%2Cvalue%29%29%20',
				'FROM%20',
				mainTable,
				'%20JOIN%20',
				attributesTable,
				'%20WHERE%20',
				mainTable,
				'%2Eid%20%3D%20',
				attributesTable,
				'%2Eid%20and%20',
				mainTable,
				'%2Eid%3D'
			)
		);
		// Return the baseURI with an appended query string, which looks up the token id in a row.
		// `&mode=json` formats into the proper JSON object expected by metadata standards.
		return
			string(
				abi.encodePacked(
					baseURI,
					query,
					Strings.toString(tokenId),
					'&mode=json'
				)
			);
	}

	/**
	 * @dev Mint an NFT, incrementing the `_tokenIds` upon each call
	 */
	function mint() public {
		_safeMint(msg.sender, _tokenIds);
		_tokenIds++;
	}
}
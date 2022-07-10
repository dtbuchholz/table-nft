// The script required to upload metadata to IPFS
const prepareMetadata = require('./uploadMetadataToIpfs')
const dotenv = require('dotenv')
dotenv.config()

/**
 * Prepare metadata for Tableland as SQL insert statements within a single table (note: not a best practice).
 * @param {string} tableName The name of the Tableland table to insert metadata values into.
 * @return {string[]} An array of SQL statements for metadata table writes.
 */
async function prepareSqlForOneTable(tableName) {
	// Prepare the metadata (handles all of the IPFS-related actions & JSON parsing)
	const metadata = await prepareMetadata()
	// An array to hold interpolated SQL INSERT statements, using the JSON metadata values
	const sqlInsertStatements = []
	for await (let obj of metadata) {
		// A classic INSERT statement -- all data is getting written to a single table
		// Schema: id int, name text, description text, image text, attributes text
		const { id, name, description, image, attributes } = obj
		const statement = `INSERT INTO ${tableName} (id, name, description, image, attributes) VALUES (${id}, '${name}', '${description}', '${image}', '${JSON.stringify(
			attributes
		)}');`
		// Note the need above to stringify the attributes
		sqlInsertStatements.push(statement)
	}

	// Return the final prepare array of SQL INSERT statements
	return sqlInsertStatements
}

/**
 * Prepare metadata for Tableland as SQL insert statements but in two tables ('main' and 'attributes').
 * @param {string} mainTable The name of the main metadata table in Tableland (id int, name text, description text, image text).
 * @param {string} attributesTable The name of the attributes table in Tableland (id int, trait_type text, value text).
 * @returns {{main: string, attributes: string[]}} SQL statements for metadata table writes.
 */
async function prepareSqlForTwoTables(mainTable, attributesTable) {
	// Prepare the metadata (handles all of the IPFS-related actions & JSON parsing).
	const metadata = await prepareMetadata()
	// An array to hold interpolated SQL INSERT statements, using the metadata object's values.
	const sqlInsertStatements = []
	for await (let obj of metadata) {
		// Destructure the metadata values from the passed object
		const { id, name, description, image, attributes } = obj
		// INSERT statement for a 'main' table that includes some shared data across any NFT
		// Schema: id int, name text, description text, image text
		let mainTableStatement = `INSERT INTO ${mainTable} (id, name, description, image) VALUES (${id}, '${name}', '${description}', '${image}');`
		// Iterate through the attributes and create an INSERT statment for each value, pushed to `attributesTableStatements`
		const attributesTableStatements = []
		for await (let attribute of attributes) {
			// Get the attirbutes trait_type & value;
			const { trait_type, value } = attribute
			// INSERT statement for a separate 'attributes' table that holds attribute data, keyed by the NFT tokenId
			// Schema: id int, trait_type text, value text
			const attributesStatement = `INSERT INTO ${attributesTable} (id, trait_type, value) VALUES (${id},'${trait_type}', '${value}');`
			attributesTableStatements.push(attributesStatement)
		}

		// Prepare the statements as a single 'statement' object
		const statement = {
			main: mainTableStatement,
			attributes: attributesTableStatements,
		}
		// Note the need above to stringify the attributes
		sqlInsertStatements.push(statement)
	}

	// Return the final prepare array of SQL INSERT statements
	return sqlInsertStatements
}

module.exports = { prepareSqlForOneTable, prepareSqlForTwoTables }

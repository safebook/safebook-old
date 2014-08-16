hash_file = (file, callback) ->
  BLOCKSIZE = 2048

  i = 0
  j = Math.min(BLOCKSIZE, file.size)
  reader = new FileReader()
  sha = new sjcl.hash.sha256()

  hash_slice = (i, j) -> reader.readAsArrayBuffer file.slice(i, j)

  reader.onloadend = (e) ->
    array = new Uint8Array @result
    bitArray = sjcl.codec.bytes.toBits(array)
    sha.update(bitArray)

    if i isnt file.size
      i = j
      j = Math.min(i + BLOCKSIZE, file.size)
      setTimeout (-> hash_slice i, j), 0
    else
      callback sha.finalize()

  hash_slice(i, j)

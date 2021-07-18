def destroy(input):
  '''
  Read a binary file and trim 30 bytes from the tail.
   Then write the trimmed result to a file `corrupted.log`.
  
  # Parameters
  * input: Name of a binary file.
  '''
  with open(input, 'rb') as original:
    contents=original.read()
    with open('corrupted.log', 'wb') as corrupted:
      corrupted.write(contents[:-30])

if __name__ == '__main__':
  import sys
  ## Receive a log file from a command line.
  destroy(sys.argv[1])

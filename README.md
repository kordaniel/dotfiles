# dotfiles
Repository where I keep my personal dotfiles.

## Notes
There is personal info in the `.gitconfig` file. If you clone or otherwise use these files, please take note of this and change the appropriate configs in this file!

## Installation

### Cloning
```console
foo@bar:~$ git clone git@github.com:kordaniel/dotfiles.git
```

### Setup
First of all you should enable the exec bit for the file `tmc-autocomplete.sh` with:
```console
foo@bar:~$ chmod ug+x .tmc-autocomplete.sh
```

#### Manual setup
After cloning the repository you will have an directory called `dotfiles` containing all the dotfiles. Files in the subdirectory `etc` are to be used system wide (placed/linked inside `/etc`), but can usually be set to be user specific as well. Simply create an symbolic link for every dotfile you wish to use:
```console
foo@bar:~$ cd dotfiles
foo@bar:~$ ln -sfnv .example_dotfile ~/.example_dotfile

```
Of course as always, remember to take backups before proceeding.

#### Automagic setup
Inside this repository is the file `setup.sh`. you can run this script with:
```console
foo@bar:~$ cd dotfiles
foo@bar:~$ chmod u+x setup.sh
foo@bar:~$ ./setup.sh
```
It will create an symbolic link for every dotfile included in this repository into your `~`. It will also create an backup for every dotfile, keeping the 2 newest backups in the directory specified in the script.

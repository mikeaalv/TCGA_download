#!/usr/bin/perl -w
use strict;
use Encode;
use JSON;
use Data::Dumper;
use URI::URL;
use URI::Escape;
my $dir = "/Users/mikeaalv/Documents/TCGA";

#initial and curl
my $project_id = "TCGA-COAD";    #should be project_id in TCGA
system("mkdir "."$project_id");
my $level = "open";
my $flag = 0; #flag 0 download open data, flag 1 download all data, if you had the necessary access; information for open data for flag 1 will be the same as all
my $filter = uri_escape("{\"op\":\"and\",\"content\":[{\"op\":\"in\",\"content\":{\"field\":\"cases.project.project_id\",\"value\":[\"".$project_id."\"]}}]}"); #for searching files or cases in this project
#project information
system("curl"." \'https://gdc-api.nci.nih.gov/projects/".$project_id."?expand=summary,summary.experimental_strategies,summary.data&pretty=true&format=TSV\' ".">./".$project_id."/".$project_id."_project.tab");
open(INPUT_project, $dir."/$project_id/$project_id"."_project.tab") or die "$!\n";
my @project_info = <INPUT_project>;
close(INPUT_project);
my $i = 0;
my @project_infor_arra = split("\t", $project_info[0]);
foreach my $info_project (@project_infor_arra)#if this kind of cancer has the same result format as the hoped one
{
    if($info_project =~ m/summary_file_count/ and !($info_project =~ m/\d/))
    {
        last;
    }
    $i += 1;
}
die "problem with finding the file count\n" if($i == scalar(@project_infor_arra));
my @project_infor_arra_num = split("\t", $project_info[1]);
my $file_num = $project_infor_arra_num[$i]; #number of files in the project
$i = 0;
foreach my $info_project (@project_infor_arra)#if this kind of cancer has the same result format as the hoped
{
    if($info_project =~ m/summary_case_count/ and !($info_project =~ m/\d/))
    {
        last;
    }
    $i += 1;
}
die "problem with finding the case count\n" if($i == scalar(@project_infor_arra));
my $case_num = $project_infor_arra_num[$i]; #number of cases in the project
$i = 0;

#whole statistics of files in the project
system("curl"." \'https://gdc-api.nci.nih.gov/files?filters=".$filter."&size=".$file_num."&format=TSV&pretty=true&from=1\' ".">./".$project_id."/".$project_id."_file.tab");
open(INPUT_files, $dir."/$project_id/".$project_id."_file.tab") or die "$!\n";
my $top_line = <INPUT_files>;
my @contents = <INPUT_files>;
close(INPUT_files);
my %colum;  #location of information in the table
my @UUID;
my %barcode;    #uuid barcode relationship
my %data_category;
my %data_category_open;
my %experimental_strategy;
my %experimental_strategy_open;
my @tops = split("\t", $top_line);
$i = 0;
#get the location of each information
foreach my $top (@tops)
{
    
    $colum{"UUID"} = $i if($top =~ m/file_id/);
    $colum{"access"} = $i if($top =~ m/access/);
    $colum{"data_category"} = $i if($top =~ m/data_category/);
    $colum{"experimental_strategy"} = $i if($top =~ m/experimental_strategy/);
    $colum{"submitter_id"} = $i if($top =~ m/submitter_id/);
    $i += 1;
}
$i = 0;
foreach my $line (@contents)    #statistics the open data and all data
{
    my @a = split("\t", $line);
    chomp @a;
    #position without information
    $a[$colum{"data_category"}] = "NA" if ($a[$colum{"data_category"}] eq "");
    $a[$colum{"experimental_strategy"}] = "NA" if ($a[$colum{"experimental_strategy"}] =~ m/^[\r\n]*$/);    #experimental_strategy with trouble in the "next line"
    if(($a[$colum{"access"}] eq $level) or ($flag))
    {
        $i += 1;
        push(@UUID, $a[$colum{"UUID"}]);
        
        if(exists $data_category_open{$a[$colum{"data_category"}]} )
        {
            $data_category_open{$a[$colum{"data_category"}]} += 1;
        }
        else
        {
            $data_category_open{$a[$colum{"data_category"}]} = 1;
        }
        
        $a[$colum{"experimental_strategy"}] =~ s/[\r\n]*//g;
        if(exists $experimental_strategy_open{$a[$colum{"experimental_strategy"}]} )
        {
            $experimental_strategy_open{$a[$colum{"experimental_strategy"}]} += 1;
        }
        else
        {
            $experimental_strategy_open{$a[$colum{"experimental_strategy"}]} = 1;
        }

    }
    if($a[$colum{"submitter_id"}] =~ m/^(?<bar>(TCGA[a-zA-Z\d\-]+))_/ or $a[$colum{"submitter_id"}] =~ m/^(?<bar>(TARGET[a-zA-Z\d\-]+))_/)  #some data seems to have no barcode
    {
        $barcode{$a[$colum{"UUID"}]} = $+{bar};
    }
    else
    {
        $barcode{$a[$colum{"UUID"}]} = "";
    }
    
    if(exists $data_category{$a[$colum{"data_category"}]} )
    {
        $data_category{$a[$colum{"data_category"}]} += 1;
    }
    else
    {
        $data_category{$a[$colum{"data_category"}]} = 1;
    }
    $a[$colum{"experimental_strategy"}] =~ s/[\r\n]*//g;
    if(exists $experimental_strategy{$a[$colum{"experimental_strategy"}]} )
    {
        $experimental_strategy{$a[$colum{"experimental_strategy"}]} += 1;
    }
    else
    {
        $experimental_strategy{$a[$colum{"experimental_strategy"}]} = 1;
    }
}
#statistics of all files
open(OUTPUT_stat, ">".$dir."/$project_id/$project_id"."_statistics") or die "$!\n";
print OUTPUT_stat "file_num: $file_num\topen: $i\n";
$i = 0;
print OUTPUT_stat "data_category: type_number\t".scalar(keys %data_category)."\n";
print OUTPUT_stat join("\t",(keys %data_category))."\n";
foreach my $key (keys %data_category)
{
    print OUTPUT_stat $data_category{$key}."\t";
}
print OUTPUT_stat "\ndata_category_open: type_number\t".scalar(keys %data_category_open)."\n";
print OUTPUT_stat join("\t",(keys %data_category))."\n";
foreach my $key (keys %data_category)
{
    if(exists $data_category_open{$key})
    {
        print OUTPUT_stat $data_category_open{$key}."\t";
    }
    else
    {
        print OUTPUT_stat "0\t";
    }
}
print OUTPUT_stat "\nexperimental_strategy: type_number\t".scalar(keys %experimental_strategy)."\n";
print OUTPUT_stat join("\t",(keys %experimental_strategy))."\n";
foreach my $key (keys %experimental_strategy)
{
    print OUTPUT_stat $experimental_strategy{$key}."\t";
}
print OUTPUT_stat "\nexperimental_strategy_open: type_number\t".scalar(keys %experimental_strategy_open)."\n";
print OUTPUT_stat join("\t",(keys %experimental_strategy))."\n";
foreach my $key (keys %experimental_strategy)
{
    if(exists $experimental_strategy_open{$key})
    {
        print OUTPUT_stat $experimental_strategy_open{$key}."\t";
    }
    else
    {
        print OUTPUT_stat "0\t";
    }
}
close(OUTPUT_stat);
$i = 0;
#barcode uuid links
open(OUTPUT_bar, ">".$dir."/$project_id/$project_id"."_barcode_uuid") or die "$!\n";
print OUTPUT_bar "UUID\tbarcode\n";
foreach my $key (keys %barcode)
{
    print OUTPUT_bar "$key\t$barcode{$key}\n";
}
close(OUTPUT_bar);

#statistics of files in each case and download according to the case
system("curl"." \'https://gdc-api.nci.nih.gov/cases?filters=".$filter."&size=".$case_num."&format=TSV&pretty=true&from=1\' ".">./".$project_id."/".$project_id."_case.tab");    #cases of each project
open(INPUT_case, $dir."/$project_id/$project_id"."_case.tab") or die "$!\n";
my $top_line_case = <INPUT_case>;
my @contents_case = <INPUT_case>;
close(INPUT_case);
my @tops_cases = split("\t", $top_line_case);
foreach my $top_case(@tops_cases)
{
    if($top_case =~ m/case_id/)
    {
        last;
    }
    $i += 1;
}
$colum{"case_id"} = $i;
$i = 0;

foreach my $line_case(@contents_case)
{
    my @b = split("\t",$line_case);
    my $case_id = $b[$colum{"case_id"}];
    #get file number in a case
    my $filter_case = uri_escape("{\"op\":\"and\",\"content\":[{\"op\":\"in\",\"content\":{\"field\":\"cases.case_id\",\"value\":[\"".$case_id."\"]}}]}");
    my @file_case_num = `curl \'https://gdc-api.nci.nih.gov/cases/$case_id?expand=summary,summary.experimental_strategies,summary.data_categories&pretty=true&format=TSV\'`;
    
    my @file_case_num_top = split("\t",$file_case_num[0]);
    $i = 0;
    foreach my $file_case_num_top_in (@file_case_num_top)
    {
        if($file_case_num_top_in =~ m/summary_file_count/)
        {
            last;
        }
        $i += 1;
    }
    die "error with file num in case\n" if($i == scalar(@file_case_num_top));
    my $file_num_in_case = $i;
    $i = 0;
    #get file information in a case
    my $file_case_uri = "curl"." \'https://gdc-api.nci.nih.gov/files?filters=".$filter_case."&size=".$file_num_in_case."&format=TSV&pretty=true&from=1\'";  #files of each case
    my @file_case = `$file_case_uri`;
    
    my @tops_case = split("\t",$file_case[0]);
    my %data_category_in_case;
    my %data_category_in_case_open;
    my %experimental_strategy_in_case;
    my %experimental_strategy_in_case_open;
    my @UUID_in_case;
    foreach my $top_case (@tops_case)
    {
        
        $colum{"UUID"} = $i if($top_case =~ m/file_id/);
        $colum{"access"} = $i if($top_case =~ m/access/);
        $colum{"data_category"} = $i if($top_case =~ m/data_category/);
        $colum{"experimental_strategy"} = $i if($top_case =~ m/experimental_strategy/);
        $i += 1;
    }
    $i = 0;
    
    foreach my $line_case (@file_case[1..(scalar(@file_case)-1)])    #statistics open data and all data
    {
        my @a = split("\t", $line_case);
        chomp @a;
        $a[$colum{"data_category"}] = "NA" if ($a[$colum{"data_category"}] eq "");
        $a[$colum{"experimental_strategy"}] = "NA" if ($a[$colum{"experimental_strategy"}] =~ m/^[\r\n]*$/);
        if(($a[$colum{"access"}] eq $level) or ($flag))
        {
            push(@UUID_in_case, $a[$colum{"UUID"}]);
            if(exists $data_category_in_case_open{$a[$colum{"data_category"}]} )
            {
                $data_category_in_case_open{$a[$colum{"data_category"}]} += 1;
            }
            else
            {
                $data_category_in_case_open{$a[$colum{"data_category"}]} = 1;
            }
            $a[$colum{"experimental_strategy"}] =~ s/[\r\n]*//g;
            if(exists $experimental_strategy_in_case_open{$a[$colum{"experimental_strategy"}]} )
            {
                $experimental_strategy_in_case_open{$a[$colum{"experimental_strategy"}]} += 1;
            }
            else
            {
                $experimental_strategy_in_case_open{$a[$colum{"experimental_strategy"}]} = 1;
            }
        }
        if(exists $data_category_in_case{$a[$colum{"data_category"}]} )
        {
            $data_category_in_case{$a[$colum{"data_category"}]} += 1;
        }
        else
        {
            $data_category_in_case{$a[$colum{"data_category"}]} = 1;
        }
        $a[$colum{"experimental_strategy"}] =~ s/[\r\n]*//g;
        if(exists $experimental_strategy_in_case{$a[$colum{"experimental_strategy"}]} )
        {
            $experimental_strategy_in_case{$a[$colum{"experimental_strategy"}]} += 1;
        }
        else
        {
            $experimental_strategy_in_case{$a[$colum{"experimental_strategy"}]} = 1;
        }
    }
    system("mkdir ./".$project_id."/".$case_id);
    open(OUTPUT_case,">".$dir."/$project_id/$case_id/file_infor") or die "error in output case information";
    print OUTPUT_case "case_id:\t$case_id\n";
    print OUTPUT_case "UUID(open):\t".join("\t", @UUID_in_case)."\n\n";
    print OUTPUT_case "data_category\n".join("\t",(keys %data_category))."\n";
    foreach my $name_category (keys %data_category)
    {
        if(exists $data_category_in_case{$name_category})
        {
            print OUTPUT_case "$data_category_in_case{$name_category}\t";
        }
        else
        {
            print OUTPUT_case "0\t";
        }
    }
    print OUTPUT_case "\ndata_category_open\n".join("\t",(keys %data_category))."\n";
    foreach my $name_category (keys %data_category)
    {
        if(exists $data_category_in_case_open{$name_category})
        {
            print OUTPUT_case "$data_category_in_case_open{$name_category}\t";
        }
        else
        {
            print OUTPUT_case "0\t";
        }
    }
    print OUTPUT_case "\nexperimental_strategy\n".join("\t",(keys %experimental_strategy))."\n";
    foreach my $name_experiment (keys %experimental_strategy)
    {
        $name_experiment =~ s/[\r\n]*//g;
        if(exists $experimental_strategy_in_case{$name_experiment})
        {
            print OUTPUT_case "$experimental_strategy_in_case{$name_experiment}\t";
        }
        else
        {
            print OUTPUT_case "0\t";
        }
    }
    print OUTPUT_case "\nexperimental_strategy_open\n".join("\t",(keys %experimental_strategy))."\n";
    foreach my $name_experiment (keys %experimental_strategy)
    {
        $name_experiment =~ s/[\r\n]*//g;
        if(exists $experimental_strategy_in_case_open{$name_experiment})
        {
            print OUTPUT_case "$experimental_strategy_in_case_open{$name_experiment}\t";
        }
        else
        {
            print OUTPUT_case "0\t";
        }
    }
    close(OUTPUT_case);
    #gdc-client if you don't have enough storage and internet, don't do the following
    system("mkdir ./".$project_id."/".$case_id."/data");
    foreach my $uuid (@UUID_in_case)
    {
      system("gdc-client "."download ".$uuid." -d"."./".$project_id."/".$case_id."/data");
    }
}

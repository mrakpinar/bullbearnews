import 'package:bullbearnews/services/poll_serivice.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../models/poll_model.dart';

class PollCard extends StatelessWidget {
  final Poll poll;

  const PollCard({super.key, required this.poll});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final hasVoted = currentUser != null && poll.hasUserVoted(currentUser.uid);
    final canShowResults =
        currentUser != null && poll.canShowResults(currentUser.uid);
    final totalVotes = canShowResults
        ? poll.options.fold(0, (sum, option) => sum + option.votes)
        : 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PollHeader(poll: poll),
            const SizedBox(height: 12),
            Text(
              poll.question,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                fontFamily: 'DMSerif',
                letterSpacing: 1.2,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            ...poll.options.map((option) => _PollOption(
                  option: option,
                  poll: poll,
                  hasVoted: hasVoted,
                  canShowResults: canShowResults,
                  totalVotes: totalVotes,
                )),
            const SizedBox(height: 12),
            _PollFooter(
              hasVoted: hasVoted,
              canShowResults: canShowResults,
              totalVotes: totalVotes,
              isActive: poll.isActive,
            ),
          ],
        ),
      ),
    );
  }
}

class _PollHeader extends StatelessWidget {
  final Poll poll;

  const _PollHeader({required this.poll});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: poll.isActive ? Colors.green : Colors.grey,
          ),
        ),
        Text(
          poll.isActive ? 'ACTIVE' : 'CLOSED',
          style: TextStyle(
            letterSpacing: 1,
            color: poll.isActive ? Colors.green : Colors.grey,
            fontFamily: 'DMSerif',
          ),
        ),
        const Spacer(),
        Icon(Icons.poll_outlined,
            color: Theme.of(context).colorScheme.secondary, size: 22),
        const SizedBox(width: 8),
        Text(
          'POLL',
          style: TextStyle(
            letterSpacing: 1,
            color: Theme.of(context).colorScheme.secondary,
            fontWeight: FontWeight.w700,
            fontFamily: 'DMSerif',
          ),
        ),
      ],
    );
  }
}

class _PollOption extends StatelessWidget {
  final PollOption option;
  final Poll poll;
  final bool hasVoted;
  final bool canShowResults;
  final int totalVotes;

  const _PollOption({
    required this.option,
    required this.poll,
    required this.hasVoted,
    required this.canShowResults,
    required this.totalVotes,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isSelected = hasVoted &&
        poll.getSelectedOptionIndex(currentUser?.uid ?? '') ==
            poll.options.indexOf(option);
    final percentage = canShowResults && totalVotes > 0
        ? (option.votes / totalVotes * 100).round()
        : 0;

    return Column(
      children: [
        InkWell(
          onTap: hasVoted || !poll.isActive
              ? null
              : () => _handleVote(context, poll, option),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.secondary
                  : hasVoted
                      ? Theme.of(context).colorScheme.primary
                      : poll.isActive
                          ? Colors.grey[200]
                          : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isSelected ? Colors.purple : Colors.grey.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : [],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    option.text,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : hasVoted || !poll.isActive
                              ? Colors.grey[600]
                              : Theme.of(context).colorScheme.primary,
                      fontFamily: 'DMSerif',
                      fontSize: 16,
                    ),
                  ),
                ),
                if (canShowResults)
                  Text(
                    '$percentage%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (canShowResults) ...[
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: totalVotes > 0 ? option.votes / totalVotes : 0,
            backgroundColor: Colors.grey[200],
            color: isSelected ? Colors.purple : Colors.purple.withOpacity(0.5),
            minHeight: 4,
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Future<void> _handleVote(
      BuildContext context, Poll poll, PollOption option) async {
    try {
      await PollService().vote(poll.id, poll.options.indexOf(option));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Vote submitted!', style: TextStyle(color: Colors.green)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}

class _PollFooter extends StatelessWidget {
  final bool hasVoted;
  final bool canShowResults;
  final int totalVotes;
  final bool isActive;

  const _PollFooter({
    required this.hasVoted,
    required this.canShowResults,
    required this.totalVotes,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            hasVoted ? Icons.check_circle : Icons.info,
            color:
                hasVoted ? Colors.green : Theme.of(context).colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasVoted
                  ? canShowResults
                      ? 'Total votes: $totalVotes'
                      : 'Thanks for voting! Results coming soon.'
                  : isActive
                      ? 'Select an option to vote'
                      : 'This poll is closed',
              style: TextStyle(
                color: hasVoted
                    ? Colors.green
                    : Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

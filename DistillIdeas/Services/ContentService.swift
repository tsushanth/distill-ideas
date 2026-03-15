//
//  ContentService.swift
//  DistillIdeas
//
//  Manages idea content, daily feed, and curated collections
//

import Foundation
import SwiftData

// MARK: - Content Service
@MainActor
@Observable
final class ContentService {
    static let shared = ContentService()

    private(set) var dailyIdeas: [Idea] = []
    private(set) var featuredIdea: Idea?
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?

    private init() {}

    // MARK: - Feed Generation

    func loadDailyFeed() async {
        isLoading = true
        errorMessage = nil

        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000)

        dailyIdeas = Self.sampleIdeas()
        featuredIdea = dailyIdeas.first(where: { $0.isFeatured })
        isLoading = false
    }

    func ideasForCategory(_ category: TopicCategory) -> [Idea] {
        Self.sampleIdeas().filter { $0.topicCategoryEnum == category }
    }

    func searchIdeas(query: String) -> [Idea] {
        let ideas = Self.sampleIdeas()
        guard !query.isEmpty else { return ideas }
        let lower = query.lowercased()
        return ideas.filter {
            $0.title.lowercased().contains(lower) ||
            $0.content.lowercased().contains(lower) ||
            $0.authorName.lowercased().contains(lower) ||
            $0.sourceName.lowercased().contains(lower) ||
            $0.tags.contains { $0.lowercased().contains(lower) }
        }
    }

    // MARK: - Sample Content

    static func sampleIdeas() -> [Idea] {
        [
            Idea(
                title: "The 2-Minute Rule",
                content: "If an action will take less than two minutes, do it immediately. This simple rule from David Allen's Getting Things Done prevents small tasks from piling up into an overwhelming list. The friction of writing something down and scheduling it often takes longer than just doing it—so for short tasks, action beats planning every time.",
                summary: "If a task takes under 2 minutes, do it now instead of scheduling it.",
                authorName: "David Allen",
                sourceName: "Getting Things Done",
                sourceType: .book,
                topicCategory: .productivity,
                tags: ["habits", "time-management", "GTD"],
                readingTimeSeconds: 45,
                isFeatured: true,
                isPremiumContent: false
            ),
            Idea(
                title: "The Spotlight Effect",
                content: "People tend to believe that others notice them far more than they actually do. In studies, participants wearing embarrassing T-shirts estimated that 50% of people noticed, while only 25% actually did. This cognitive bias causes unnecessary social anxiety—most people are too focused on themselves to scrutinize you as much as you think.",
                summary: "You overestimate how much others notice you. Most people are focused on themselves.",
                authorName: "Thomas Gilovich",
                sourceName: "The Spotlight Effect Research",
                sourceType: .research,
                topicCategory: .psychology,
                tags: ["cognitive-bias", "social-anxiety", "self-awareness"],
                readingTimeSeconds: 50,
                isFeatured: false,
                isPremiumContent: false
            ),
            Idea(
                title: "Deep Work Requires Ritual",
                content: "Cal Newport argues that the ability to focus without distraction on cognitively demanding tasks is becoming increasingly rare and valuable. Professionals who cultivate this skill create rituals around deep work: specific locations, set times, clear rules about internet use, and support systems like coffee and good music. Without intentional design, shallow work crowds out deep work.",
                summary: "Protect focused work time by creating rituals and removing distractions deliberately.",
                authorName: "Cal Newport",
                sourceName: "Deep Work",
                sourceType: .book,
                topicCategory: .productivity,
                tags: ["focus", "deep-work", "habits", "career"],
                readingTimeSeconds: 55,
                isFeatured: false,
                isPremiumContent: false
            ),
            Idea(
                title: "The Socratic Method",
                content: "Socrates taught not by lecturing but by asking questions that exposed contradictions in his students' beliefs. Rather than presenting answers, he guided others to discover truth through dialogue. This method reveals that genuine understanding comes from questioning assumptions—not from passive acceptance. The best learning is active, not receptive.",
                summary: "True understanding comes from questioning assumptions, not accepting answers passively.",
                authorName: "Socrates",
                sourceName: "The Dialogues of Plato",
                sourceType: .book,
                topicCategory: .philosophy,
                tags: ["learning", "critical-thinking", "dialogue"],
                readingTimeSeconds: 48,
                isFeatured: false,
                isPremiumContent: true
            ),
            Idea(
                title: "Neuroplasticity: The Brain Rewires Itself",
                content: "For decades, scientists believed the adult brain was fixed and unchangeable. We now know that neurons form new connections throughout life. Every time you learn something new, practice a skill, or change a habit, your brain physically rewires itself. This means your intelligence, personality, and abilities are not fixed—they're shaped by what you repeatedly do and think.",
                summary: "Your brain physically rewires itself through learning and practice, making change always possible.",
                authorName: "Michael Merzenich",
                sourceName: "Soft-Wired",
                sourceType: .book,
                topicCategory: .science,
                tags: ["neuroscience", "learning", "growth-mindset"],
                readingTimeSeconds: 52,
                isFeatured: false,
                isPremiumContent: true
            ),
            Idea(
                title: "The Pareto Principle in Business",
                content: "Vilfredo Pareto observed that 80% of Italy's land was owned by 20% of the population. This 80/20 principle appears everywhere in business: 20% of customers generate 80% of revenue, 20% of products drive 80% of profit, 20% of bugs cause 80% of crashes. Identifying your vital 20% and focusing your energy there produces disproportionate results.",
                summary: "80% of outcomes come from 20% of inputs. Identify and focus on the vital few.",
                authorName: "Vilfredo Pareto",
                sourceName: "Pareto Principle",
                sourceType: .research,
                topicCategory: .business,
                tags: ["productivity", "business-strategy", "prioritization"],
                readingTimeSeconds: 50,
                isFeatured: false,
                isPremiumContent: true
            ),
            Idea(
                title: "Sleep is When Memory Consolidates",
                content: "During sleep, the hippocampus replays memories and transfers them to the neocortex for long-term storage. Studies show that sleeping immediately after learning improves retention by up to 40% compared to staying awake. The glymphatic system also clears metabolic waste from the brain during sleep—waste linked to Alzheimer's disease. Sleep isn't passive rest; it's active memory consolidation.",
                summary: "Sleep consolidates memory and clears brain waste. Sleeping after learning boosts retention by 40%.",
                authorName: "Matthew Walker",
                sourceName: "Why We Sleep",
                sourceType: .book,
                topicCategory: .health,
                tags: ["sleep", "memory", "neuroscience", "learning"],
                readingTimeSeconds: 55,
                isFeatured: false,
                isPremiumContent: true
            ),
            Idea(
                title: "First Principles Thinking",
                content: "Most people reason by analogy—copying what others do with small modifications. First principles thinking means breaking problems down to their fundamental truths and reasoning up from there. Elon Musk used this to reduce rocket costs by 10x: instead of buying rockets, he asked 'what are rockets made of?' and found the raw materials cost 2% of the rocket price.",
                summary: "Break problems down to fundamental truths and rebuild solutions from scratch rather than copying others.",
                authorName: "Elon Musk",
                sourceName: "Lex Fridman Podcast",
                sourceType: .podcast,
                topicCategory: .productivity,
                tags: ["thinking", "innovation", "problem-solving"],
                readingTimeSeconds: 55,
                isFeatured: false,
                isPremiumContent: false
            ),
            Idea(
                title: "Cognitive Dissonance Drives Behavior Change",
                content: "Leon Festinger discovered that when our actions conflict with our beliefs, we experience uncomfortable tension—cognitive dissonance. To reduce this discomfort, we change either our behavior or our beliefs. Marketers and coaches use this: get someone to make a small public commitment, and they'll adjust their beliefs and behavior to stay consistent. The foot-in-the-door technique works the same way.",
                summary: "We change beliefs or behavior to reduce tension when they conflict—use small commitments to drive change.",
                authorName: "Leon Festinger",
                sourceName: "A Theory of Cognitive Dissonance",
                sourceType: .research,
                topicCategory: .psychology,
                tags: ["psychology", "behavior-change", "persuasion"],
                readingTimeSeconds: 52,
                isFeatured: false,
                isPremiumContent: false
            ),
            Idea(
                title: "The Compounding Effect of Daily Habits",
                content: "James Clear explains that getting 1% better every day leads to being 37 times better after a year. Conversely, getting 1% worse each day leads to nearly zero. The compounding effect means small habits—barely noticeable in the short term—create massive differences in the long term. Systems beat goals because systems determine whether you show up every day.",
                summary: "1% daily improvement compounds to 37x improvement in a year. Build systems, not just goals.",
                authorName: "James Clear",
                sourceName: "Atomic Habits",
                sourceType: .book,
                topicCategory: .productivity,
                tags: ["habits", "compounding", "self-improvement"],
                readingTimeSeconds: 50,
                isFeatured: false,
                isPremiumContent: false
            ),
            Idea(
                title: "The Stoic View of Control",
                content: "The Stoics divided everything into two categories: what is 'up to us' (our judgments, intentions, desires, aversions) and what is 'not up to us' (body, reputation, possessions, positions of power). Epictetus taught that suffering arises from trying to control what we cannot. Freedom comes from focusing exclusively on our own responses—the only thing truly within our power.",
                summary: "Distinguish what you control (your responses) from what you don't. Focus only on the former.",
                authorName: "Epictetus",
                sourceName: "The Enchiridion",
                sourceType: .book,
                topicCategory: .philosophy,
                tags: ["stoicism", "mental-health", "resilience"],
                readingTimeSeconds: 50,
                isFeatured: false,
                isPremiumContent: true
            ),
            Idea(
                title: "The Power of Compounding Interest",
                content: "Einstein allegedly called compound interest the eighth wonder of the world. If you invest $10,000 at 10% annual return for 30 years, you end up with $174,494—17x your investment. Wait 40 years and it's $452,593—45x. The key is starting early: the same $10,000 invested at age 25 vs 35 creates a $173,000 difference by retirement, even though you only delayed 10 years.",
                summary: "Compound interest multiplies wealth exponentially. Starting early is the single most powerful financial decision.",
                authorName: "Warren Buffett",
                sourceName: "The Snowball",
                sourceType: .book,
                topicCategory: .finance,
                tags: ["investing", "compounding", "wealth", "personal-finance"],
                readingTimeSeconds: 55,
                isFeatured: false,
                isPremiumContent: true
            ),
        ]
    }
}
